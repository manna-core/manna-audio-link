# Manna Audio Link v0.1.2

Game-launch stability release.

## What Changed

- Added receiver presets:
  - `Low Latency`
  - `Balanced`
  - `Gaming / Stable`
- The tray app can switch presets from the right-click menu.
- The Gaming preset uses a larger receiver buffer.
- The Gaming preset raises receiver process priority when Windows allows it.
- The receiver can now reset its playback device after repeated underruns or a long packet gap.

## Why

Launching a heavy game can temporarily starve Windows audio scheduling. In live testing, simply raising the receiver buffer did not fix the issue, and the receiver could stay in a broken-sounding state after the game closed. The new reset path is meant to recover that stuck audio output without requiring a full app restart.

## Downloads

- `MannaSoundSync-0.1.2-Receiver-Setup.exe` - install on the main PC
- `MannaSendAudio-0.1.2-Sender-Setup.exe` - install on the laptop
- `.sha256.txt` files - checksums for verifying downloads

## Validation

- Python syntax check passed.
- Packet unit tests passed.
- PowerShell launcher parse check passed.
- Receiver CLI help shows the new reset options.
