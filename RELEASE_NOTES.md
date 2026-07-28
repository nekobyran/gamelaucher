# GameLauncher 1.0.0 Preview 2

This is a **private pre-release** build for controlled testing. It is
not a stable release and must not be redistributed.

## Downloads

- `GameLauncher-1.0.0-preview.2-windows-x64-setup.exe`
  - Windows x64 current-user installer.
  - Installs to `%LOCALAPPDATA%\Programs\GameLauncher`.
  - Not Authenticode-signed; Windows SmartScreen may warn or block it.
- `gamelaucher-android-stable-full-engines-arm64-v8a.apk`
  - Android ARM64 full-engine resource bundle, package
    `org.github.gamelauncher.app`.
  - Version `1.0.0` (`versionCode 2`), `arm64-v8a` only.
  - Signed with a debug certificate. It contains packaged Wine, EasyRPG, and
    DXVK 3.0.1 resources, but no DDLC or other built-in game data.
  - The current runtime manifests still mark Native Wine and EasyRPG as not
    runnable on Android. This asset is a full-resource preview, not proof of
    Windows-game compatibility.

SHA-256 values are provided in `checksums-full-engines.txt` as a Release asset.

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
- The full-resource APK does not yet have a successful full-engine gameplay or
  game-packaging test video.

## Verified Packaging Scope

- The three priority compatibility suites passed `49/49`.
- Windows x64 release build and Preview 2 current-user installer isolation
  smoke passed.
- Android full-resource APK is `1.0.0` (`versionCode 2`); APK Signature Scheme
  v2/v3 verification passed; only `arm64-v8a`; packaged Wine/EasyRPG/DXVK
  resources are present, with no test games or DDLC data.
