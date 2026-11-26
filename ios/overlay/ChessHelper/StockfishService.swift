import Foundation
import SwiftStockfish

/// One line of the engine's answer.
struct EngineLine {
    var multipv: Int
    var depth: Int
    var score: Int          // centipawns, from the side to move; forced mates are +-30000
    var move: String        // "e2e4"
}

/// Drives the real Stockfish 19 engine through the SwiftStockfish UCI bridge.
final class StockfishService: @unchecked Sendable {
    private let lock = NSLock()
    private var engine: StockfishEngine?
    private var listener: Task<Void, Never>?
    private var lines: [Int: EngineLine] = [:]
    private var continuation: CheckedContinuation<[EngineLine], Never>?
    private var readyContinuation: CheckedContinuation<Bool, Never>?
    private var searching = false
    private var ready = false

    deinit {
        listener?.cancel()
        engine?.shutdown()
    }

    // MARK: start

    /// Downloads and verifies Stockfish 19's official NNUE network on first launch,
    /// then starts the native engine. The network is cached in Application Support.
    func start() async -> Bool {
        lock.lock()
        let alreadyReady = ready
        lock.unlock()
        if alreadyReady { return true }

        let support = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        let networkDirectory = support.appendingPathComponent(
            "ChessHelper/Stockfish19",
            isDirectory: true
        )

        do {
            try await StockfishNetworkLoader().ensure(in: networkDirectory)
        } catch {
            return false
        }

        // Engine creation starts a native worker thread; keep it off the UI thread.
        let newEngine = await Task.detached(priority: .utility) {
            StockfishEngine(networkDirectory: networkDirectory)
        }.value

        guard let newEngine else { return false }

        lock.lock()
        engine = newEngine
        lock.unlock()

        listener = Task { [weak self, newEngine] in
            for await line in newEngine.output {
                self?.handle(line)
            }
        }

        return await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            lock.lock()
            readyContinuation = cont
            lock.unlock()
            newEngine.uci()
        }
    }

    // MARK: search

    /// Thinks about a position for `movetimeMs` milliseconds and returns the lines, best first.
    func search(fen: String, movetimeMs: Int, multipv: Int) async -> [EngineLine] {
        guard ready, let currentEngine = currentEngine() else { return [] }
        await cancelRunning()

        return await withCheckedContinuation { (cont: CheckedContinuation<[EngineLine], Never>) in
            lock.lock()
            lines = [:]
            continuation = cont
            searching = true
            lock.unlock()

            currentEngine.send("setoption name MultiPV value \(max(1, multipv))")
            currentEngine.send("position fen \(fen)")
            currentEngine.send("go movetime \(max(1, movetimeMs))")
        }
    }

    func stopSearch() async {
        await cancelRunning()
    }

    func newGame() async {
        await cancelRunning()
        currentEngine()?.send("ucinewgame")
    }

    // MARK: UCI output

    private func handle(_ line: String) {
        if line == "uciok" {
            let current = currentEngine()
            let cores = ProcessInfo.processInfo.activeProcessorCount
            current?.send("setoption name Threads value \(min(max(cores, 1), 4))")
            current?.send("setoption name Hash value 64")
            current?.send("isready")
            return
        }

        if line == "readyok" {
            lock.lock()
            ready = true
            let cont = readyContinuation
            readyContinuation = nil
            lock.unlock()
            cont?.resume(returning: true)
            return
        }

        if line.hasPrefix("info ") {
            if let parsed = parseInfo(line) {
                store(parsed)
            }
            return
        }

        if line.hasPrefix("bestmove ") {
            let tokens = line.split(whereSeparator: \.isWhitespace)
            if tokens.count >= 2 {
                finish(bestMove: String(tokens[1]))
            } else {
                finish(bestMove: "")
            }
        }
    }

    private func parseInfo(_ line: String) -> EngineLine? {
        let tokens = line.split(whereSeparator: \.isWhitespace).map(String.init)
        guard tokens.first == "info",
              let depthIndex = tokens.firstIndex(of: "depth"),
              depthIndex + 1 < tokens.count,
              let depth = Int(tokens[depthIndex + 1]),
              let scoreIndex = tokens.firstIndex(of: "score"),
              scoreIndex + 2 < tokens.count,
              let rawScore = Int(tokens[scoreIndex + 2]),
              let pvIndex = tokens.firstIndex(of: "pv"),
              pvIndex + 1 < tokens.count
        else { return nil }

        if tokens.contains("lowerbound") || tokens.contains("upperbound") {
            return nil
        }

        let scoreType = tokens[scoreIndex + 1]
        let value: Int
        switch scoreType {
        case "cp":
            value = rawScore
        case "mate":
            value = rawScore > 0 ? 30000 - rawScore : -30000 - rawScore
        default:
            return nil
        }

        let multipv: Int
        if let index = tokens.firstIndex(of: "multipv"),
           index + 1 < tokens.count,
           let parsed = Int(tokens[index + 1]) {
            multipv = parsed
        } else {
            multipv = 1
        }

        return EngineLine(
            multipv: multipv,
            depth: depth,
            score: value,
            move: tokens[pvIndex + 1]
        )
    }

    // MARK: internal state

    private func currentEngine() -> StockfishEngine? {
        lock.lock()
        defer { lock.unlock() }
        return engine
    }

    private func store(_ line: EngineLine) {
        lock.lock()
        if let old = lines[line.multipv], old.depth > line.depth {
            lock.unlock()
            return
        }
        lines[line.multipv] = line
        lock.unlock()
    }

    private func finish(bestMove: String) {
        lock.lock()
        searching = false
        let cont = continuation
        continuation = nil
        var result = lines.values.sorted { $0.multipv < $1.multipv }
        lock.unlock()

        guard let cont else { return }
        if !bestMove.isEmpty {
            if let index = result.firstIndex(where: { $0.move == bestMove }) {
                let best = result.remove(at: index)
                result.insert(best, at: 0)
            } else {
                let score = result.first?.score ?? 0
                result.insert(
                    EngineLine(multipv: 1, depth: 0, score: score, move: bestMove),
                    at: 0
                )
            }
        }
        cont.resume(returning: result)
    }

    private func isSearching() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return searching
    }

    private func cancelRunning() async {
        lock.lock()
        let cont = continuation
        continuation = nil
        let wasSearching = searching
        lock.unlock()

        cont?.resume(returning: [])
        if wasSearching {
            currentEngine()?.send("stop")
            for _ in 0..<40 {
                if !isSearching() { break }
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }
}
