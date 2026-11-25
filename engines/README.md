# Add your own engine (optional)

Put an **Android build** of a UCI chess engine here and the workflow will pack it into the APK as the Engine Agent:

- `engines/arm64/<name>`  - for the 64-bit APK (aarch64 Android executable)
- `engines/arm32/<name>`  - for the 32-bit APK (armv7 Android executable)

It must be a program (not a `.so` library) built for Android with the NDK, speak UCI, and support `MultiPV`.
Linux/Windows/Mac engine files will not run on a phone. If an engine does not start, the app ignores it.
The Engine Agent only gives a second opinion (it breaks near-ties and can offer a faster forced mate); Stockfish stays in charge.
