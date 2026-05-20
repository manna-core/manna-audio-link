# Next Steps - Manna Audio Link

## Best Next Move

Publish and live-test the packaged release:

1. Push the source repo to GitHub under `manna-core/manna-audio-link`.
2. Create GitHub release `v0.1.0`.
3. Attach both installer EXEs and SHA-256 sidecars.
4. On the main PC, install `MannaSoundSync-0.1.0-Receiver-Setup.exe`.
5. Launch `Manna Sound Sync` from Windows search and confirm the tray receiver says `Waiting for laptop`.
6. On the laptop, install `MannaSendAudio-0.1.0-Sender-Setup.exe`.
7. Enter the main PC IPv4 address during sender setup.
8. Launch `Manna Send Audio` from Windows search.
9. Confirm the visible sender stats move, the receiver tray changes to `Playing`, and headphone audio stays clean.

## If The Main PC IP Changes

Launch:

```text
Configure Manna Send Audio
```

or run:

```powershell
.\configure-sender.ps1
```

The sender target lives at:

```text
%APPDATA%\Manna Audio Link\sender-config.json
```

## If Audio Quality Regresses

If it sounds distorted and sender `clipped` rises, lower gain:

```powershell
.\run-sender.ps1 -Target MAIN_PC_IP -Gain 0.65
```

If it crackles and receiver `missing`, `late`, or `underruns` rises, increase prebuffer:

```powershell
.\run-receiver.ps1 -PrebufferPackets 24
```

## Release Commands

Build installers:

```powershell
.\scripts\build-installers.ps1
```

Smoke test installers:

```powershell
.\scripts\smoke-installers.ps1
```

Artifacts:

```text
dist\installer\MannaSoundSync-0.1.0-Receiver-Setup.exe
dist\installer\MannaSendAudio-0.1.0-Sender-Setup.exe
```

## Not Yet

- automatic pairing
- encryption/authentication
- multiple senders
- laptop tray app
- cloud relay
- public-internet streaming

Those stay out until the installer-based LAN path is proven comfortable on the actual two-machine setup.
