from __future__ import annotations

from dataclasses import dataclass
from typing import Any


def _load_audio_deps() -> tuple[Any, Any]:
    try:
        import numpy as np
        import soundcard as sc
    except ImportError as exc:
        raise RuntimeError(
            "Audio dependencies are missing. Run .\\setup.ps1 first."
        ) from exc
    return np, sc


def _device_name(device: Any) -> str:
    return str(getattr(device, "name", device))


def _find_by_fragment(devices: list[Any], fragment: str | None) -> Any | None:
    if not fragment:
        return None

    needle = fragment.lower()
    for device in devices:
        if needle in _device_name(device).lower():
            return device
    return None


def describe_audio_devices() -> str:
    _np, sc = _load_audio_deps()
    speakers = list(sc.all_speakers())
    loopbacks = list(sc.all_microphones(include_loopback=True))

    lines = ["Output devices / loopback capture targets:"]
    for index, speaker in enumerate(speakers, start=1):
        lines.append(f"  {index}. {_device_name(speaker)}")

    lines.append("")
    lines.append("Loopback-capable microphone entries:")
    for index, microphone in enumerate(loopbacks, start=1):
        lines.append(f"  {index}. {_device_name(microphone)}")

    return "\n".join(lines)


def _normalize_channels(samples: Any, channels: int, np: Any) -> Any:
    data = np.asarray(samples, dtype=np.float32)
    if data.ndim == 1:
        data = data.reshape((-1, 1))
    if data.shape[1] == channels:
        return np.clip(data, -1.0, 1.0)
    if data.shape[1] > channels:
        return np.clip(data[:, :channels], -1.0, 1.0)

    repeats = channels - data.shape[1]
    padding = np.repeat(data[:, -1:], repeats, axis=1)
    return np.clip(np.concatenate([data, padding], axis=1), -1.0, 1.0)


@dataclass(frozen=True)
class PcmBlock:
    pcm16: bytes
    frames: int
    peak: float
    clipped_samples: int


def _float_to_pcm16(samples: Any, gain: float, np: Any) -> tuple[bytes, float, int]:
    gained = samples * gain
    peak = float(np.max(np.abs(gained))) if gained.size else 0.0
    clipped_samples = int(np.count_nonzero(np.abs(gained) > 1.0))
    clipped = np.clip(gained, -1.0, 1.0)
    return (clipped * 32767.0).astype(np.int16).tobytes(), peak, clipped_samples


def _pcm16_to_float(pcm16: bytes, channels: int, np: Any) -> Any:
    data = np.frombuffer(pcm16, dtype=np.int16).astype(np.float32) / 32768.0
    return data.reshape((-1, channels))


@dataclass
class LoopbackCapture:
    sample_rate: int
    channels: int
    block_frames: int
    device_fragment: str | None = None
    gain: float = 1.0

    def __post_init__(self) -> None:
        self._np: Any = None
        self._recorder_context: Any = None
        self._recorder: Any = None
        self.device_name = ""

    def __enter__(self) -> "LoopbackCapture":
        self._np, sc = _load_audio_deps()
        speakers = list(sc.all_speakers())
        speaker = _find_by_fragment(speakers, self.device_fragment) or sc.default_speaker()
        self.device_name = _device_name(speaker)

        try:
            microphone = sc.get_microphone(id=self.device_name, include_loopback=True)
        except Exception:
            loopbacks = list(sc.all_microphones(include_loopback=True))
            microphone = _find_by_fragment(loopbacks, self.device_name)
            if microphone is None:
                microphone = _find_by_fragment(loopbacks, self.device_fragment)
            if microphone is None:
                raise RuntimeError(
                    f"Could not find a loopback capture device for {self.device_name!r}."
                )

        kwargs = {
            "samplerate": self.sample_rate,
            "blocksize": self.block_frames,
        }
        try:
            self._recorder_context = microphone.recorder(
                channels=self.channels,
                **kwargs,
            )
        except TypeError:
            self._recorder_context = microphone.recorder(**kwargs)

        self._recorder = self._recorder_context.__enter__()
        return self

    def __exit__(self, exc_type: Any, exc: Any, tb: Any) -> None:
        if self._recorder_context is not None:
            self._recorder_context.__exit__(exc_type, exc, tb)

    def read_pcm16(self) -> PcmBlock:
        samples = self._recorder.record(numframes=self.block_frames)
        normalized = _normalize_channels(samples, self.channels, self._np)
        pcm16, peak, clipped_samples = _float_to_pcm16(
            normalized,
            self.gain,
            self._np,
        )
        return PcmBlock(
            pcm16=pcm16,
            frames=int(normalized.shape[0]),
            peak=peak,
            clipped_samples=clipped_samples,
        )


@dataclass
class AudioOutput:
    sample_rate: int
    channels: int
    device_fragment: str | None = None
    block_frames: int | None = None

    def __post_init__(self) -> None:
        self._np: Any = None
        self._player_context: Any = None
        self._player: Any = None
        self.device_name = ""

    def __enter__(self) -> "AudioOutput":
        self._np, sc = _load_audio_deps()
        speakers = list(sc.all_speakers())
        speaker = _find_by_fragment(speakers, self.device_fragment) or sc.default_speaker()
        self.device_name = _device_name(speaker)

        kwargs: dict[str, Any] = {"samplerate": self.sample_rate}
        if self.block_frames:
            kwargs["blocksize"] = self.block_frames

        try:
            self._player_context = speaker.player(channels=self.channels, **kwargs)
        except TypeError:
            self._player_context = speaker.player(**kwargs)

        self._player = self._player_context.__enter__()
        return self

    def __exit__(self, exc_type: Any, exc: Any, tb: Any) -> None:
        if self._player_context is not None:
            self._player_context.__exit__(exc_type, exc, tb)

    def play_pcm16(self, pcm16: bytes) -> None:
        samples = _pcm16_to_float(pcm16, self.channels, self._np)
        self._player.play(samples)

    def play_silence(self, frames: int) -> None:
        silence = self._np.zeros((frames, self.channels), dtype=self._np.float32)
        self._player.play(silence)
