# Next Steps - Manna Audio Link

## Best Next Move

Live-test the public `v0.1.2` game-launch stability path:

1. Main PC: install `MannaSoundSync-0.1.2-Receiver-Setup.exe` from the GitHub release.
2. Main PC: launch `Manna Sound Sync` from Windows search.
3. Main PC: right-click the tray icon and choose `Preset` -> `Gaming / Stable`.
4. Laptop: keep using the sender installer/app; reinstall only if needed.
5. Start laptop audio and confirm normal playback first.
6. Launch `Subnautica 2`.
7. If audio gets weird, wait a few seconds and check whether it recovers automatically.
8. Right-click tray -> `Open logs` and inspect whether `resets` increased.

Release:

```text
https://github.com/manna-core/manna-audio-link/releases/tag/v0.1.2
```

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

First try the tray preset:

```text
Manna Sound Sync tray -> Preset -> Gaming / Stable
```

Source users can run:

```powershell
.\run-receiver.ps1 -Preset gaming
```

If it sounds distorted and sender `clipped` rises, lower gain:

```powershell
.\run-sender.ps1 -Target MAIN_PC_IP -Gain 0.65
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
dist\installer\MannaSoundSync-0.1.2-Receiver-Setup.exe
dist\installer\MannaSendAudio-0.1.2-Sender-Setup.exe
```

## Recommended Next Product Move

After the Subnautica 2 launch test:

- if `Gaming / Stable` recovers automatically, keep v0.1.2 as the public baseline
- if it still stays corrupted, add an explicit tray `Restart receiver` action and consider a more robust playback backend
- only consider discovery/pairing after game-launch stability is proven

## Not Yet

- automatic pairing
- encryption/authentication
- multiple senders
- laptop tray app
- cloud relay
- public-internet streaming

Those stay out until the installer-based LAN path is proven comfortable on the actual two-machine setup.
