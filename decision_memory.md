# Decision Memory - Manna Audio Link

## 2026-05-19 - Start With Direct LAN Audio

Decision: make the main PC the receiver and the laptop the sender.

Reason: Grayson's headphones are on the main PC while the laptop is the secondary media source. The main PC can run a background receiver before launching a fullscreen game, and the laptop can send its audio without needing the game to care.

## 2026-05-19 - Use Python First

Decision: use Python with `soundcard` and `numpy` for the first MVP.

Reason: this machine has Python available, no .NET SDK, and no ffmpeg on PATH. Python gives the fastest path to a small readable prototype with Windows loopback capture.

Caution: Python 3.14 dependency install worked on the main PC. If wheels are a problem on the laptop, create the venv with Python 3.12 instead of changing the product architecture.

## 2026-05-19 - UDP PCM Before Fancy Audio Codecs

Decision: use small PCM16 UDP packets first.

Reason: the local LAN use case values simple behavior and low ceremony over bandwidth optimization. A 48 kHz stereo PCM stream is reasonable on a home LAN.

Caution: keep packet duration small enough to avoid UDP fragmentation. The default is `5 ms`.

## 2026-05-19 - No Discovery Yet

Decision: require the main PC IP manually for the first test.

Reason: direct IP is the shortest truthful path to finding out whether the audio capture/playback core works. Discovery and pairing are polish after the signal path is real.

## 2026-05-20 - Quality Before UI

Decision: after the first real stream worked but sounded staticy/distorted, tune quality before adding pairing or a tray surface.

Reason: the product promise is simple audio that is actually pleasant to use. A prettier launcher would be fake progress if the stream clips or starves.

Implementation direction: use larger `10 ms` packets, a little more receiver prebuffer, sender gain control, and live `clipped` / `missing` / `underruns` counters before reaching for heavier codecs or drivers.

## 2026-05-20 - Tray Polish After Clean Audio

Decision: add `Manna Sound Sync` as the Windows-searchable main-PC tray launcher after Grayson confirmed the stream was clean and low-lag.

Reason: the project had crossed from prototype to daily-use utility. The highest remaining friction was not audio code; it was having to open PowerShell and remember commands.

Implementation direction: keep the proven command-line receiver intact and wrap it with a tray process that starts/stops it, shows status, opens logs, and exposes the local IP helper.

## 2026-05-20 - Package As Two Role Installers

Decision: ship `Manna Audio Link` as one GitHub repo with two Windows installers: `Manna Sound Sync` for the main PC receiver and `Manna Send Audio` for the laptop sender.

Reason: the real user workflow has two different machines and two different jobs. A single generic installer would make strangers think too hard at the exact moment the tool should feel simple.

Implementation direction: keep one shared source/runtime tree, but compile separate Inno Setup installers. The sender installer asks for the main PC IP and writes `%APPDATA%\Manna Audio Link\sender-config.json`; the launcher reads that config instead of hardcoding a local address.

Caution: do not let packaging become an excuse to add discovery, pairing, cloud relay, or a laptop tray app yet. The release promise is still direct LAN audio with a configurable receiver IP.
