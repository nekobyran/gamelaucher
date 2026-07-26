# GameLauncher 1.0.0 Preview 1

This is a **private, draft, pre-release** build for controlled testing. It is
not a stable release and must not be redistributed.

## Downloads

- `GameLauncher-1.0.0-preview.1-windows-x64-setup.exe`
  - Windows x64 current-user installer.
  - Installs to `%LOCALAPPDATA%\Programs\GameLauncher`.
  - Not Authenticode-signed; Windows SmartScreen may warn or block it.
- `gamelaucher-android-stable-arm64-v8a-slim.apk`
  - Android ARM64 launcher shell, package `org.github.gamelauncher.app`.
  - Version `1.0.0` (`versionCode 1`), `arm64-v8a` only.
  - Signed with a debug certificate. It contains no DDLC game data and no
    runnable Native Wine/full-engine runtime.

SHA-256 values are provided in `checksums.txt` and as a Release asset.

## Test Recordings

- `GameLauncher-1.0.0-preview.1-android-arm64-mumu-test.mp4`
  - MuMu slim APK replacement-install and first-launch diagnostic.
  - The recording is playable, but MuMu reported an Activity launch timeout
    and the recording session experienced a codec/device disconnect. It is not
    proof of a successful sub-60-second first launch.
- `GameLauncher-1.0.0-preview.1-android-arm64-cached-launch.mp4`
  - MuMu cached-launch diagnostic. Measured command elapsed time was about
    53.2 seconds, but Android returned `Status: timeout` / unknown launch state.
- `mumu-full-engine-install-launch-candidate-not-released.mp4`
  - MuMu full-engine candidate install/cold-launch recording. Install succeeded
    and the Activity cold launch completed in about 38.1 seconds.
  - The corresponding full-engine APK is intentionally not released because
    the Native Wine runtime is not runnable yet. This video is not gameplay or
    FPS evidence.

All recordings are video-only diagnostics and are not performance-authority
captures. They must not be used to claim real rendered FPS.

## Known Limitations

- Huawei physical-device acceptance remains pending: DDLC start under 60
  seconds, at least 110 real presented FPS, IME name input, true fullscreen,
  and removal of side black bars are not verified.
- Frame interpolation and super-resolution are not verified as complete or
  active in real gameplay.
- MuMu is limited to a 60 Hz display mode in the tested environment and cannot
  validate a 110/120 FPS physical-screen target.
- The DDLC V129 packaged runtime crashes under MuMu Houdini in `libextras.so`
  before a real game window appears. No DDLC V129 APK or game content is
  included in this Release.
- No full-engine gameplay/package test video is claimed in this preview.

## Verified Packaging Scope

- Windows stable bundle: release optimization checks `13/13`, slim bundle
  checks `16/16`; installer isolation smoke passed.
- Android slim APK: APK Signature Scheme v2/v3 verification passed; only
  `arm64-v8a`; no test games, nested APKs, DDLC data, or bundled game runtimes.
- Video files were checked with `ffprobe` and SHA-256 before upload.

