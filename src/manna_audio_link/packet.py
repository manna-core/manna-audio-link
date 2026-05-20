from __future__ import annotations

from dataclasses import dataclass
import struct


MAGIC = b"MAL1"
VERSION = 1
FORMAT_PCM16 = 1

_HEADER = struct.Struct("!4sBBIIBBH")


@dataclass(frozen=True)
class AudioPacket:
    sequence: int
    sample_rate: int
    channels: int
    frames: int
    pcm16: bytes


def pack_audio_packet(
    sequence: int,
    sample_rate: int,
    channels: int,
    frames: int,
    pcm16: bytes,
) -> bytes:
    if sample_rate <= 0:
        raise ValueError("sample_rate must be positive")
    if not 1 <= channels <= 8:
        raise ValueError("channels must be between 1 and 8")
    if not 1 <= frames <= 65535:
        raise ValueError("frames must be between 1 and 65535")

    expected_payload_bytes = frames * channels * 2
    if len(pcm16) != expected_payload_bytes:
        raise ValueError(
            f"PCM payload is {len(pcm16)} bytes, expected {expected_payload_bytes}"
        )

    header = _HEADER.pack(
        MAGIC,
        VERSION,
        channels,
        sequence & 0xFFFFFFFF,
        sample_rate,
        FORMAT_PCM16,
        0,
        frames,
    )
    return header + pcm16


def unpack_audio_packet(data: bytes) -> AudioPacket:
    if len(data) < _HEADER.size:
        raise ValueError("packet too small")

    magic, version, channels, sequence, sample_rate, audio_format, _reserved, frames = (
        _HEADER.unpack_from(data)
    )
    if magic != MAGIC:
        raise ValueError("bad packet magic")
    if version != VERSION:
        raise ValueError(f"unsupported packet version {version}")
    if audio_format != FORMAT_PCM16:
        raise ValueError(f"unsupported audio format {audio_format}")
    if not 1 <= channels <= 8:
        raise ValueError(f"invalid channel count {channels}")
    if sample_rate <= 0:
        raise ValueError("invalid sample rate")
    if frames <= 0:
        raise ValueError("invalid frame count")

    pcm16 = data[_HEADER.size :]
    expected_payload_bytes = frames * channels * 2
    if len(pcm16) != expected_payload_bytes:
        raise ValueError(
            f"PCM payload is {len(pcm16)} bytes, expected {expected_payload_bytes}"
        )

    return AudioPacket(
        sequence=sequence,
        sample_rate=sample_rate,
        channels=channels,
        frames=frames,
        pcm16=pcm16,
    )
