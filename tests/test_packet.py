import unittest

from manna_audio_link.packet import pack_audio_packet, unpack_audio_packet


class AudioPacketTests(unittest.TestCase):
    def test_packet_roundtrip(self) -> None:
        pcm = b"\x00\x00\x01\x00" * 240
        packed = pack_audio_packet(
            sequence=42,
            sample_rate=48000,
            channels=2,
            frames=240,
            pcm16=pcm,
        )

        packet = unpack_audio_packet(packed)

        self.assertEqual(packet.sequence, 42)
        self.assertEqual(packet.sample_rate, 48000)
        self.assertEqual(packet.channels, 2)
        self.assertEqual(packet.frames, 240)
        self.assertEqual(packet.pcm16, pcm)

    def test_rejects_short_payload(self) -> None:
        with self.assertRaises(ValueError):
            pack_audio_packet(
                sequence=1,
                sample_rate=48000,
                channels=2,
                frames=240,
                pcm16=b"too short",
            )


if __name__ == "__main__":
    unittest.main()
