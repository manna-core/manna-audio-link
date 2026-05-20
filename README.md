# Manna Audio Link

Tiny Windows LAN audio bridge for one simple job:

- the main PC runs the receiver and keeps using the normal headphones
- the laptop streams its system audio to the main PC
- both machines stay on the same local network

This is meant for setups like: play a fullscreen game on the main PC, watch a video on the laptop, and hear both through the main PC headphones.

## Download

Use the latest GitHub release.

- Install `MannaSoundSync-*-Receiver-Setup.exe` on the main PC.
- Install `MannaSendAudio-*-Sender-Setup.exe` on the laptop.
- During the sender install, enter the main PC IPv4 address.

If Windows Firewall asks, allow private-network access. This app is LAN-only. Do not expose UDP port `44555` to the public internet.

## Everyday Use

On the main PC:

1. Open Windows search.
2. Launch `Manna Sound Sync`.
3. Right-click the tray icon.
4. Use `Show main PC IPs` if you need the address for the laptop.

The receiver installer can also show the main PC IP on the final setup screen. Leave `Show this main PC's IP for the laptop sender` checked if you are about to install the laptop sender.

On the laptop:

1. Open Windows search.
2. Launch `Manna Send Audio`.
3. Leave the sender window open while listening.
4. Press `Ctrl+C` in that window to stop sending audio.

## Changing The Main PC IP

If the main PC IP changes, launch:

```text
Configure Manna Send Audio
```

or run this from the install/source folder:

```powershell
.\configure-sender.ps1
```

The sender config is stored at:

```text
%APPDATA%\Manna Audio Link\sender-config.json
```

## Source Setup

Clone the repo, then run:

```powershell
.\setup.ps1
```

Main PC receiver:

```powershell
.\run-receiver.ps1
```

Laptop sender:

```powershell
.\configure-sender.ps1
.\run-sender.ps1
```

You can still pass the target manually:

```powershell
.\run-sender.ps1 -Target 192.168.1.25
```

## Device Selection

List available audio devices:

```powershell
.\list-devices.ps1
```

Pick devices by a name fragment:

```powershell
.\run-receiver.ps1 -OutputDevice "Headphones"
.\run-sender.ps1 -Target 192.168.1.25 -InputDevice "Speakers"
```

On the laptop, `-InputDevice` means the speaker/output device whose loopback audio should be captured.

## Current Defaults

- UDP port: `44555`
- sample rate: `48000`
- channels: stereo
- packet size: `10 ms`
- sender gain: `0.85`
- receiver prebuffer: `16` packets

Lower prebuffer means less delay but more crackle risk. Higher prebuffer means smoother audio but more delay.

## Static Or Distortion

If the stream sounds harsh and sender `clipped` rises, lower laptop sender gain:

```powershell
.\run-sender.ps1 -Target 192.168.1.25 -Gain 0.65
```

If it crackles or drops out, raise the main PC receiver prebuffer:

```powershell
.\run-receiver.ps1 -PrebufferPackets 24
```

Receiver status reports `missing`, `late`, and `underruns`. Sender status reports `peak` and `clipped`.

## Build Installers

This repo uses the same safer installer lane as other small Manna utilities: source app plus a bundled local Python runtime, compiled with Inno Setup.

Requirements:

- Windows
- Python 3.10+
- Inno Setup 6

Build:

```powershell
.\scripts\build-installers.ps1
```

Smoke test:

```powershell
.\scripts\smoke-installers.ps1
```

Release artifacts are written to:

```text
dist\installer
```

## Known Limits

- LAN-only; no encryption or authentication yet.
- One laptop sender at a time.
- No automatic discovery or pairing yet.
- No laptop tray app yet.
- Some protected or DRM app audio can behave strangely depending on Windows output routing.
