# Chess Helper for iPhone / iPad

A normal iOS app (SwiftUI) with its own board. iOS does not allow a floating
window over other apps, so it cannot float over a chess app the way the Android
version does. It is for practice and bot games.

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
