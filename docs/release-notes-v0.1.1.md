# Manna Audio Link v0.1.1

Small setup quality-of-life release.

## What Changed

- The receiver installer now offers a final setup option to show the main PC IP for the laptop sender.
- The IP helper now explicitly says to enter the Wi-Fi/Ethernet IPv4 during `Manna Send Audio` setup.

## Downloads

- `MannaSoundSync-0.1.1-Receiver-Setup.exe` - install on the main PC
- `MannaSendAudio-0.1.1-Sender-Setup.exe` - install on the laptop
- `.sha256.txt` files - checksums for verifying downloads

## Quick Start

1. Install the receiver on the main PC.
2. On the final receiver setup screen, leave `Show this main PC's IP for the laptop sender` checked.
3. Use the shown Wi-Fi/Ethernet IPv4 address during laptop sender setup.
4. Install the sender on the laptop.
5. Launch `Manna Sound Sync` on the main PC and `Manna Send Audio` on the laptop.

## Validation

- Python syntax check passed.
- Packet unit tests passed.
- PowerShell launcher parse check passed.
- Receiver and sender installers built successfully with Inno Setup.
- Silent install smoke passed for both installers.
- Installed runtime import smoke passed for `numpy`, `soundcard`, `PIL`, `pystray`, and `manna_audio_link`.
