# Current State - Manna Audio Link

## Active Goal

Create a super simple Windows LAN audio bridge:

- laptop captures its own system audio
- main PC receives the stream
- main PC plays it through the same headphones already used for games

## Current Phase

Phase 5 - Public release live-test and game-launch stability hardening.

## Built This Batch

- Created the project at `D:\Manna-core\projects\manna-audio-link`; the current synced working folder for this batch is `C:\Manna-core\projects\manna-audio-link`.
- Added a Python sender/receiver package under `src/manna_audio_link`.
- Added UDP PCM packet framing with a small unit test.
- Added PowerShell launchers:
  - `setup.ps1`
  - `run-receiver.ps1`
  - `run-sender.ps1`
  - `list-devices.ps1`
  - `show-local-ip.ps1`
- Added a laptop-side Codex handoff prompt.
- Added project ignore rules for venvs, Python caches, and build outputs.
- Added root `.stignore` patterns so project venvs and generated caches do not become Syncthing noise.
- Confirmed the first real two-machine stream works.
- Confirmed the tuned stream is clean and has no noticeable lag in live use.
- Added audio-quality tuning:
  - sender packet default increased from `5 ms` to `10 ms`
  - sender gain control added with default `0.85`
  - receiver prebuffer increased from `12` to `16` packets
  - receiver max buffer increased to `120` packets
  - receiver now reports `missing` packets and `underruns`
  - receiver now skips late/out-of-order packets instead of playing stale audio
  - sender now reports signal `peak` and cumulative `clipped` samples
- Added `Manna Sound Sync` main-PC tray surface:
  - tray wrapper starts/stops the proven receiver as a hidden subprocess
  - tray menu shows status, laptop sender, output device, receiver stats, logs, and IP helper
  - Start Menu shortcut installer makes it searchable from Windows search
- Added `Manna Send Audio` laptop launcher polish:
  - `launch-manna-send-audio.ps1` runs the sender from the project or installed app folder
  - sender window stays visible so packet stats can be watched
  - `install-laptop-send-shortcut.ps1` creates a searchable Start Menu shortcut named `Manna Send Audio`
  - `uninstall-laptop-send-shortcut.ps1` removes that shortcut
- Added installer-ready sender configuration:
  - `configure-sender.ps1` writes `%APPDATA%\Manna Audio Link\sender-config.json`
  - `run-sender.ps1` can now read target/port/gain/block size/input device from that config
  - `launch-manna-send-audio.ps1` prompts for the main PC IP on first run if config is missing
- Added public release surface:
  - `LICENSE`
  - `PRIVACY.md`
  - `.gitattributes`
  - app icons under `assets/icons`
  - `docs/release-notes-v0.1.0.md`
- Added role-specific installer lane:
  - `installer/receiver.iss` builds the main-PC `Manna Sound Sync` receiver installer
  - `installer/sender.iss` builds the laptop `Manna Send Audio` sender installer
  - the sender installer asks for the main PC receiver IP and writes the sender config
  - `scripts/build-installers.ps1` stages the app plus bundled Python runtime and builds both installers
  - `scripts/smoke-installers.ps1` silently installs both roles and validates the installed runtime
- Published the project publicly:
  - repo: `https://github.com/manna-core/manna-audio-link`
  - latest release: `https://github.com/manna-core/manna-audio-link/releases/tag/v0.1.1`
  - release assets:
    - `MannaSoundSync-0.1.1-Receiver-Setup.exe`
    - `MannaSoundSync-0.1.1-Receiver-Setup.sha256.txt`
    - `MannaSendAudio-0.1.1-Sender-Setup.exe`
    - `MannaSendAudio-0.1.1-Sender-Setup.sha256.txt`
- Added `v0.1.1` receiver setup QOL:
  - final receiver setup screen now offers `Show this main PC's IP for the laptop sender`
  - the IP helper explicitly tells users to enter the Wi-Fi/Ethernet IPv4 during laptop sender setup
- Added `v0.1.2` game-launch stability hardening:
  - tray receiver now has `Low Latency`, `Balanced`, and `Gaming / Stable` presets
  - `Gaming / Stable` uses a larger receiver buffer
  - `Gaming / Stable` raises receiver process priority when Windows allows it
  - receiver can reset its playback device after repeated underruns or a long packet gap
  - source CLI supports `.\run-receiver.ps1 -Preset gaming`
  - latest release: `https://github.com/manna-core/manna-audio-link/releases/tag/v0.1.2`

## Runtime Design

- The main PC should run `run-receiver.ps1`.
- For daily use, the main PC should launch `Manna Sound Sync` from Windows search.
- The laptop can run `configure-sender.ps1` once, then `run-sender.ps1`.
- For daily use on the laptop, Windows search can launch `Manna Send Audio`, which opens a visible PowerShell sender window and reads the configured main PC target from `%APPDATA%\Manna Audio Link\sender-config.json`.
- "Same internet" should mean same Wi-Fi/router/local network for the MVP.
- Audio capture/playback uses Python packages:
  - `soundcard`
  - `numpy`
- Network transport is UDP on port `44555`.
- Default packet size is `10 ms` to reduce scheduling/network churn while avoiding oversized UDP packets on normal LANs.
- Game-launch choppiness is now treated as an audio-output recovery problem, not only a network-buffer problem, because Grayson confirmed larger `-PrebufferPackets 32 -MaxBufferPackets 200` did not fix it and the bad audio state survived after the game closed.

## Verification

- Code syntax and packet unit tests have been verified locally.
- `setup.ps1` succeeded locally under Python 3.14.
- `list-devices.ps1` succeeded and saw `Headphones (Arctis 5 Game)` as the available output / loopback target.
- `show-local-ip.ps1` succeeded and labels VPN adapters separately from normal Ethernet/Wi-Fi addresses.
- Laptop-side setup succeeded from `C:\Manna-core\projects\manna-audio-link`.
- Laptop sender started successfully against the main PC LAN IP and captured loopback from `Speakers (High Definition Audio Device)`.
- Grayson confirmed the stream actually works and audio reaches the shared headphones.
- Grayson confirmed the tuned stream is clean and has no noticeable lag.
- Tray app code has been added but still needs local dependency install and launch verification.
- Tray dependencies installed locally and Start Menu shortcut was created at `C:\Users\Admin\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Manna Sound Sync.lnk`.
- Verification found UDP port `44555` currently owned by a `python` receiver process, so the tray app was not auto-launched on top of the live receiver.
- New laptop shortcut scripts parse successfully under PowerShell AST checks.
- `install-laptop-send-shortcut.ps1` installed `Manna Send Audio.lnk` under the user Start Menu Programs folder.
- Packaging verification passed:
  - Python syntax check for package modules
  - packet unit tests via `unittest`
  - PowerShell parse check for launch/build/smoke scripts
  - `scripts/build-installers.ps1` built:
    - `dist\installer\MannaSoundSync-0.1.0-Receiver-Setup.exe`
    - `dist\installer\MannaSendAudio-0.1.0-Sender-Setup.exe`
    - SHA-256 sidecar files for both installers
  - `scripts\smoke-installers.ps1` silently installed both roles into `runtime\install-smoke`
  - installed runtime import smoke passed for `numpy`, `soundcard`, `PIL`, `pystray`, and `manna_audio_link`
  - sender installer config-write path produced a target config with UDP port `44555`
- GitHub verification passed:
  - `manna-core/manna-audio-link` exists and is public
  - `main` tracks `origin/main`
  - release `v0.1.1` exists with four uploaded assets
- `v0.1.2` verification passed:
  - Python syntax check for package modules
  - packet unit tests via `unittest`
  - PowerShell parse check for launch/build/smoke scripts
  - receiver CLI help exposes playback reset options
  - `scripts/build-installers.ps1` built fresh `0.1.2` receiver/sender installers and SHA-256 sidecars
  - `scripts\smoke-installers.ps1` silently installed both roles and passed installed runtime import smoke
  - GitHub release `v0.1.2` exists with four uploaded assets

## Important Cautions

- Keep this LAN-only. Being on the same public internet is not enough; the first version expects both machines behind the same router/Wi-Fi.
- Do not expose the UDP port to the internet.
- Do not add discovery/pairing until the direct IP path proves reliable.
- Do not install random virtual audio drivers for the MVP.
- If sender `clipped` rises, lower `-Gain` before changing architecture.
- If receiver `missing`, `late`, or `underruns` rises, increase `-PrebufferPackets` before adding complex networking.
- If the tray says `Port already in use`, stop any old `run-receiver.ps1` window before starting the tray receiver.
- Python 3.14 dependency install worked on this machine; if `soundcard` or `numpy` wheels lag on the laptop, use Python 3.12 for the project venv rather than rewriting the app.
- The laptop sender shortcut is intentionally foreground-only for now. Do not add a laptop tray app, pairing, discovery, cloud, accounts, or extra UI before this direct shortcut path is proven pleasant.
- If the main PC IP changes, use `Configure Manna Send Audio` or rerun `configure-sender.ps1`; do not reintroduce a hardcoded target IP into the launcher.
- The published release is locally smoke-tested but still needs a real two-machine installer-path test on the actual main PC and laptop before calling the release fully field-proven.
- If game launch still corrupts audio in `Gaming / Stable`, inspect receiver logs for `underruns`, `resets`, and whether resets occur after the game launch. The next likely fix would be moving playback onto a more robust output backend or adding an explicit tray `Restart receiver` recovery button.
