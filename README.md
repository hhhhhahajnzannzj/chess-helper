# Chess Helper (Android)

A floating chess board. You tap the moves (yours and the opponent's) on it, and on your turn it shows the best
move on its own board with a BLUE box on the piece, a BLUE box on the target square and an ARROW.
It reads nothing from the screen (no screen capture). It has no internet permission, no accounts and no keys.

Window controls: Done (plays the shown move for you), Undo move, New game, Choose your mode (Bullet / Blitz
(Lightning) / Rapid / Daily), Think (Instant by default, 1-30 s, no cap), Automatic Done (Off, 1-5 s), Auto Save (the game
survives closing), Unpredictable, With Brilliant (!!) (strict: real, deeply verified piece sacrifice), Use best
Gambit/Trap (~420 book lines incl. 38 extra traps/gambits/tricks, move-checked), Counter Gambit/Trap (recognises a gambit/trap from the
opponent's moves), Fast Checkmate 100% (complete mate search; shown mates are always real; deep quiet mates can be
missed within the time limit), Worst move (red box + arrow), Mid move (yellow box + arrow), My pieces, Board size.
The gear in the title bar hides/shows all feature buttons (long-press: choose which); the X asks "Are you sure to close?".

Engine: iterative deepening with transposition table, null-move and late-move reductions, killer/history ordering,
repetition awareness and an evaluation with pawn structure, king shelter, mobility and endgame mop-up.

Build: upload the zip to a GitHub repo; the Actions workflow builds `ChessHelper.apk` and publishes it under Releases.
Use for practice and games against the computer; most chess sites forbid engine help in games against people.
