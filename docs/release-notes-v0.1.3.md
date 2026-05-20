# Manna Audio Link v0.1.3

Simplified stability release.

## What Changed

- The proven stable receiver behavior is now the default.
- Removed the tray preset menu.
- `Manna Sound Sync` is now just on/off instead of mode-based.
- Receiver still uses:
  - larger buffering
  - higher process priority when Windows allows it
  - playback reset after repeated underruns or a long packet gap

## Why

Live testing showed `Gaming / Stable` fixed the Subnautica 2 launch corruption case. Since that is the more complete and reliable behavior, it should not be hidden behind a mode selector.

## Downloads

- `MannaSoundSync-0.1.3-Receiver-Setup.exe` - install on the main PC
- `MannaSendAudio-0.1.3-Sender-Setup.exe` - install on the laptop
- `.sha256.txt` files - checksums for verifying downloads

## Validation

- Python syntax check passed.
- Packet unit tests passed.
- PowerShell launcher parse check passed.
- Receiver and sender installers built successfully with Inno Setup.
- Silent install smoke passed for both installers.
