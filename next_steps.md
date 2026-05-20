# Next Steps - Manna Audio Link

## Best Next Move

Use `v0.1.3` as the public baseline and live-test the simplified stable receiver:

1. Main PC: install `MannaSoundSync-0.1.3-Receiver-Setup.exe` from the GitHub release.
2. Main PC: launch `Manna Sound Sync` from Windows search.
3. Laptop: keep using the sender app; reinstall only if needed.
4. Start laptop audio and confirm normal playback first.
5. Launch `Subnautica 2`.
6. Confirm audio stays usable or recovers automatically.
7. If audio gets weird, right-click tray -> `Open logs` and inspect whether `resets` increased.

Release:

```text
https://github.com/manna-core/manna-audio-link/releases/tag/v0.1.3
```

## Product Baseline

The receiver should feel like on/off software, not a tuner panel.

- stable buffering is default
- process priority lift is default when Windows allows it
- playback reset recovery is default
- no visible low-latency/balanced/gaming mode selector

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
dist\installer\MannaSoundSync-0.1.3-Receiver-Setup.exe
dist\installer\MannaSendAudio-0.1.3-Sender-Setup.exe
```

## Recommended Next Product Move

After another real Subnautica 2 launch test:

- if stable default holds, leave the product alone for now
- if it still corrupts, add an explicit tray `Restart receiver` recovery action
- only consider discovery/pairing after stability is boring

## Not Yet

- automatic pairing
- encryption/authentication
- multiple senders
- laptop tray app
- cloud relay
- public-internet streaming

Those stay out until the installer-based LAN path is proven comfortable on the actual two-machine setup.
