# Chess Helper for iPhone / iPad

A normal iOS app (SwiftUI) with its own board. iOS does not allow a free
floating window over other apps, so it cannot float over a chess app the way the
Android version does; it has a floating Picture in Picture board instead (see
below). It is for practice and bot games.

* The iOS app now uses **Stockfish 19**, through the native SwiftStockfish
  package. It sends UCI commands to the real Stockfish 19 engine; this is not a
  version-label change or a renamed Stockfish 17 binary.
* On first launch, the app downloads Stockfish 19's required NNUE network
  (about 100 MB) into Application Support. The package verifies the network's
  SHA-256 before the engine starts. An internet connection is required for
  this one-time setup; later starts use the cached network.
* Tap every move on the board (the opponent's and yours). On your turn the
  engine shows the best move with two blue boxes and a blue arrow. "Done" plays
  it, "Undo move", "New game" (asks first), "Think time" (Instant to 30 s),
  "My pieces" (White/Black), pawn promotion chooser.
* Not in the iPhone version: Safe Mode, Unpredictable, With Brilliant,
  Gambits/Traps and SuperChess (Stockfish plus companion engines). Those exist
  only in the Android and Windows apps.

## How it is built

GitHub Actions builds the app on a macOS runner with XcodeGen + xcodebuild and
packs an **unsigned** `ChessHelper-iOS.ipa`. The build forces the SwiftStockfish
source build with baseline ARM NEON so the iOS app does not require the
precompiled package's newer ARM dot-product CPU feature.

## Installing an unsigned .ipa

Apple only runs signed apps, so you sign it yourself with a free Apple ID,
using one of:
* Sideloadly, AltStore or SideStore: free Apple ID, the app must be re-signed
  every 7 days.
* TrollStore (only on some iOS versions): permanent.

The app has not been tested on every iPhone/iPad model. Use for practice and
bot games; most chess sites forbid engine help in games against people.

## Floating board (Picture in Picture)

iOS has no "display over other apps" permission, so the app cannot float a window like the Android version. What iOS does allow is
Picture in Picture (the small video window). The app draws the board and the blue move as pictures and shows them there:

1. Open the app and tap **Floating board (PiP)**. A small window with the board and the suggested move appears and stays on top of
   other apps (it also starts by itself when you leave the app). You can drag and resize it.
2. Switch to your chess app. Look at the window for the blue move.
3. The window cannot take touches. To enter a move, go back to Chess Helper, tap the move, and the window updates.

Needs Settings > General > Picture in Picture turned on. The build adds the "audio" background mode that the system requires for it
(no sound is played, and other apps' sounds keep playing). This was written without being able to run it on an iPhone, so it
may need a fix after the first real test.
