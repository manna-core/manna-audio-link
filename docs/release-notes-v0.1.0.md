# Manna Audio Link v0.1.0

First public release.

## What It Does

`Manna Audio Link` lets a Windows laptop stream its system audio to a Windows main PC over the local network, so laptop audio can play through the main PC headphones.

## Downloads

- `MannaSoundSync-0.1.0-Receiver-Setup.exe` - install on the main PC
- `MannaSendAudio-0.1.0-Sender-Setup.exe` - install on the laptop
- `.sha256.txt` files - checksums for verifying downloads

## Quick Start

1. Install the receiver on the main PC.
2. Launch `Manna Sound Sync` from Windows search.
3. Use the tray menu's `Show main PC IPs` action to find the main PC IPv4 address.
4. Install the sender on the laptop.
5. Enter the main PC IPv4 address during sender setup.
6. Launch `Manna Send Audio` from Windows search.

## Notes

- This is LAN-only.
- Use the same Wi-Fi/router/local network.
- Do not expose UDP port `44555` to the public internet.
- The sender target can be changed later with `Configure Manna Send Audio`.

## Validation

- Python syntax check passed.
- Packet unit tests passed.
- PowerShell launcher parse check passed.
- Receiver and sender installers built successfully with Inno Setup.
- Silent install smoke passed for both installers.
- Installed runtime import smoke passed for `numpy`, `soundcard`, `PIL`, `pystray`, and `manna_audio_link`.
