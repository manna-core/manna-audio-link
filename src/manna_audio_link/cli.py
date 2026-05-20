from __future__ import annotations

import argparse
from collections import deque
from dataclasses import dataclass
import socket
import threading
import time
from typing import Any

from .audio_backend import AudioOutput, LoopbackCapture, describe_audio_devices
from .packet import AudioPacket, pack_audio_packet, unpack_audio_packet


DEFAULT_PORT = 44555
DEFAULT_SAMPLE_RATE = 48000
DEFAULT_CHANNELS = 2
DEFAULT_BLOCK_MS = 10
DEFAULT_GAIN = 0.85
DEFAULT_PREBUFFER_PACKETS = 16
DEFAULT_MAX_BUFFER_PACKETS = 120


class PacketBuffer:
    def __init__(self, max_packets: int) -> None:
        self._packets: deque[AudioPacket] = deque()
        self._condition = threading.Condition()
        self.max_packets = max(2, max_packets)
        self.dropped_packets = 0

    def append(self, packet: AudioPacket) -> None:
        with self._condition:
            if len(self._packets) >= self.max_packets:
                self._packets.popleft()
                self.dropped_packets += 1
            self._packets.append(packet)
            self._condition.notify_all()

    def depth(self) -> int:
        with self._condition:
            return len(self._packets)

    def wait_for_depth(self, depth: int, timeout: float | None = None) -> bool:
        end_time = None if timeout is None else time.monotonic() + timeout
        with self._condition:
            while len(self._packets) < depth:
                if end_time is None:
                    remaining = None
                else:
                    remaining = end_time - time.monotonic()
                    if remaining <= 0:
                        return False
                self._condition.wait(remaining)
            return True

    def peek(self) -> AudioPacket | None:
        with self._condition:
            if not self._packets:
                return None
            return self._packets[0]

    def pop(self, timeout: float | None = None) -> AudioPacket | None:
        end_time = None if timeout is None else time.monotonic() + timeout
        with self._condition:
            while not self._packets:
                if end_time is None:
                    remaining = None
                else:
                    remaining = end_time - time.monotonic()
                    if remaining <= 0:
                        return None
                self._condition.wait(remaining)
            return self._packets.popleft()


@dataclass
class ReceiverStats:
    packets: int = 0
    invalid_packets: int = 0
    last_remote: tuple[str, int] | None = None
    last_sequence: int | None = None
    out_of_order: int = 0
    underruns: int = 0
    missing_packets: int = 0
    late_packets: int = 0
    output_resets: int = 0


def _block_frames(sample_rate: int, block_ms: int) -> int:
    return max(64, int(sample_rate * (block_ms / 1000.0)))


def _print_stats(prefix: str, last_print: float, counters: dict[str, Any]) -> float:
    now = time.monotonic()
    if now - last_print < 2.0:
        return last_print

    parts = [f"{key}={value}" for key, value in counters.items()]
    print(f"{prefix} " + " ".join(parts), flush=True)
    return now


def run_sender(args: argparse.Namespace) -> int:
    block_frames = _block_frames(args.sample_rate, args.block_ms)
    target = (args.target, args.port)
    gain = max(0.05, min(float(args.gain), 2.0))

    print(
        f"Sending laptop audio to {args.target}:{args.port} "
        f"at {args.sample_rate} Hz, {args.channels}ch, "
        f"{args.block_ms} ms packets, gain {gain:.2f}.",
        flush=True,
    )
    print("Press Ctrl+C to stop.", flush=True)

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.connect(target)

    sequence = 0
    sent_packets = 0
    sent_frames = 0
    clipped_samples = 0
    latest_peak = 0.0
    last_stats = time.monotonic()

    try:
        with LoopbackCapture(
            sample_rate=args.sample_rate,
            channels=args.channels,
            block_frames=block_frames,
            device_fragment=args.input_device,
            gain=gain,
        ) as capture:
            print(f"Capturing loopback from: {capture.device_name}", flush=True)
            while True:
                block = capture.read_pcm16()
                clipped_samples += block.clipped_samples
                latest_peak = block.peak
                packet = pack_audio_packet(
                    sequence=sequence,
                    sample_rate=args.sample_rate,
                    channels=args.channels,
                    frames=block.frames,
                    pcm16=block.pcm16,
                )
                sock.send(packet)
                sequence = (sequence + 1) & 0xFFFFFFFF
                sent_packets += 1
                sent_frames += block.frames
                last_stats = _print_stats(
                    "sender",
                    last_stats,
                    {
                        "packets": sent_packets,
                        "seconds": round(sent_frames / args.sample_rate, 1),
                        "peak": round(latest_peak, 2),
                        "clipped": clipped_samples,
                    },
                )
    except KeyboardInterrupt:
        print("\nSender stopped.", flush=True)
        return 0


def _receiver_thread(
    sock: socket.socket,
    buffer: PacketBuffer,
    stats: ReceiverStats,
    stop_event: threading.Event,
) -> None:
    sock.settimeout(0.5)
    while not stop_event.is_set():
        try:
            data, remote = sock.recvfrom(65535)
        except socket.timeout:
            continue
        except OSError:
            break

        try:
            packet = unpack_audio_packet(data)
        except ValueError:
            stats.invalid_packets += 1
            continue

        if stats.last_remote is None:
            print(f"Receiving from {remote[0]}:{remote[1]}", flush=True)
        stats.last_remote = remote
        if stats.last_sequence is not None:
            expected = (stats.last_sequence + 1) & 0xFFFFFFFF
            if packet.sequence != expected:
                stats.out_of_order += 1
        stats.last_sequence = packet.sequence
        stats.packets += 1
        buffer.append(packet)


def run_receiver(args: argparse.Namespace) -> int:
    bind = (args.host, args.port)
    buffer = PacketBuffer(max_packets=args.max_buffer_packets)
    stats = ReceiverStats()
    stop_event = threading.Event()

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(bind)

    print(f"Listening for laptop audio on {args.host}:{args.port}", flush=True)
    print("Start the laptop sender now. Press Ctrl+C to stop.", flush=True)

    thread = threading.Thread(
        target=_receiver_thread,
        args=(sock, buffer, stats, stop_event),
        daemon=True,
    )
    thread.start()

    try:
        if not buffer.wait_for_depth(1, timeout=None):
            return 1
        first = buffer.peek()
        if first is None:
            return 1

        prebuffer_packets = max(1, args.prebuffer_packets)
        print(f"Prebuffering {prebuffer_packets} packets...", flush=True)
        buffer.wait_for_depth(prebuffer_packets, timeout=5.0)

        output_context: AudioOutput | None = None
        output: AudioOutput | None = None

        def open_output() -> AudioOutput:
            context = AudioOutput(
                sample_rate=first.sample_rate,
                channels=first.channels,
                device_fragment=args.output_device,
                block_frames=first.frames,
            )
            opened = context.__enter__()
            nonlocal output_context
            output_context = context
            return opened

        def close_output() -> None:
            nonlocal output_context
            if output_context is not None:
                output_context.__exit__(None, None, None)
                output_context = None

        def reset_output(reason: str) -> AudioOutput:
            nonlocal output
            stats.output_resets += 1
            print(f"Resetting playback device after {reason}...", flush=True)
            close_output()
            time.sleep(0.2)
            output = open_output()
            print(f"Playing through: {output.device_name}", flush=True)
            return output

        try:
            output = open_output()
            print(f"Playing through: {output.device_name}", flush=True)
            last_stats = time.monotonic()
            last_frames = first.frames
            last_played_sequence: int | None = None
            consecutive_underruns = 0
            last_packet_time = time.monotonic()

            while True:
                packet = buffer.pop(timeout=0.25)
                if packet is None:
                    stats.underruns += 1
                    consecutive_underruns += 1
                    if (
                        args.reset_after_underruns > 0
                        and consecutive_underruns >= args.reset_after_underruns
                    ):
                        output = reset_output(f"{consecutive_underruns} underruns")
                        consecutive_underruns = 0
                    output.play_silence(last_frames)
                    continue

                if (
                    packet.sample_rate != first.sample_rate
                    or packet.channels != first.channels
                ):
                    continue

                now = time.monotonic()
                if (
                    args.reset_after_gap_seconds > 0
                    and now - last_packet_time >= args.reset_after_gap_seconds
                ):
                    output = reset_output(f"{round(now - last_packet_time, 2)}s packet gap")
                last_packet_time = now
                consecutive_underruns = 0
                last_frames = packet.frames
                if last_played_sequence is not None:
                    expected = (last_played_sequence + 1) & 0xFFFFFFFF
                    gap = packet.sequence - expected
                    if gap < 0:
                        stats.late_packets += 1
                        continue
                    if 0 < gap < 50:
                        stats.missing_packets += gap
                        for _ in range(min(gap, args.gap_fill_packets)):
                            output.play_silence(last_frames)
                last_played_sequence = packet.sequence
                output.play_pcm16(packet.pcm16)
                last_stats = _print_stats(
                    "receiver",
                    last_stats,
                    {
                        "buffer": buffer.depth(),
                        "packets": stats.packets,
                        "dropped": buffer.dropped_packets,
                        "reordered": stats.out_of_order,
                        "missing": stats.missing_packets,
                        "late": stats.late_packets,
                        "underruns": stats.underruns,
                        "resets": stats.output_resets,
                        "bad": stats.invalid_packets,
                    },
                )
        finally:
            close_output()
    except KeyboardInterrupt:
        print("\nReceiver stopped.", flush=True)
        return 0
    finally:
        stop_event.set()
        sock.close()


def run_devices(_args: argparse.Namespace) -> int:
    print(describe_audio_devices())
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="manna-audio-link",
        description="Minimal local-network audio bridge.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    send = subparsers.add_parser("send", help="stream this computer's system audio")
    send.add_argument("--target", required=True, help="receiver IP or hostname")
    send.add_argument("--port", type=int, default=DEFAULT_PORT)
    send.add_argument("--sample-rate", type=int, default=DEFAULT_SAMPLE_RATE)
    send.add_argument("--channels", type=int, default=DEFAULT_CHANNELS)
    send.add_argument("--block-ms", type=int, default=DEFAULT_BLOCK_MS)
    send.add_argument("--gain", type=float, default=DEFAULT_GAIN)
    send.add_argument("--input-device", default=None, help="speaker name fragment")
    send.set_defaults(func=run_sender)

    receive = subparsers.add_parser("receive", help="play incoming LAN audio")
    receive.add_argument("--host", default="0.0.0.0")
    receive.add_argument("--port", type=int, default=DEFAULT_PORT)
    receive.add_argument("--output-device", default=None, help="speaker name fragment")
    receive.add_argument("--prebuffer-packets", type=int, default=DEFAULT_PREBUFFER_PACKETS)
    receive.add_argument("--max-buffer-packets", type=int, default=DEFAULT_MAX_BUFFER_PACKETS)
    receive.add_argument("--gap-fill-packets", type=int, default=3)
    receive.add_argument("--reset-after-underruns", type=int, default=0)
    receive.add_argument("--reset-after-gap-seconds", type=float, default=0.0)
    receive.set_defaults(func=run_receiver)

    devices = subparsers.add_parser("devices", help="list audio devices")
    devices.set_defaults(func=run_devices)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return int(args.func(args))
