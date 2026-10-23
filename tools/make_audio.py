"""Original soft bell/plucked cues. Rebuild with Python standard library only."""
from array import array
from pathlib import Path
import math
import sys
import wave

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "game" / "assets" / "audio"


def midi(number):
    return 440 * 2 ** ((number - 69) / 12)


def render(name, seconds, notes):
    samples = [0.0] * int(seconds * RATE)
    for start, note, duration, volume in notes:
        frequency = midi(note)
        for i in range(int(duration * RATE)):
            target = round(start * RATE) + i
            if target >= len(samples):
                break
            t = i / RATE
            envelope = min(1, t / 0.012) * min(1, (duration - t) / 0.08) * math.exp(-4.5 * t / duration)
            tone = (math.sin(math.tau * frequency * t)
                    + 0.24 * math.sin(math.tau * frequency * 2 * t) * math.exp(-6 * t)
                    + 0.06 * math.sin(math.tau * frequency * 3 * t) * math.exp(-9 * t))
            samples[target] += tone * envelope * volume
    peak = max(1.0, max(abs(v) for v in samples) / 0.85)
    pcm = array("h", (round(max(-1, min(1, v / peak)) * 32767) for v in samples))
    if sys.byteorder != "little":
        pcm.byteswap()
    with wave.open(str(OUT / name), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(pcm.tobytes())


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    render("collect.wav", 0.9, [(0, 76, .45, .45), (.09, 79, .5, .35), (.19, 84, .62, .3)])
    render("complete.wav", 1.8, [(i * .14, note, .9, .32) for i, note in enumerate([72, 76, 79, 84, 88])])
    render("retry.wav", .5, [(0, 67, .3, .13), (.13, 72, .35, .12)])
    render("jump.wav", .48, [(0, 60, .24, .23), (.07, 67, .27, .16), (.14, 72, .32, .12)])
    melody = [76, 79, 81, 79, 76, 74, 72, 74, 76, 79, 84, 81, 79, 76, 74, 72]
    notes = [(i * .75, note, 1.0, .15) for i, note in enumerate(melody)]
    for bar, chord in enumerate([(48, 60, 64, 67), (45, 60, 64, 69), (53, 60, 65, 69), (55, 59, 62, 67)]):
        for beat in range(4):
            notes.append((bar * 3 + beat * .75, chord[beat], 1.15, .1))
    render("meadow.wav", 12.0, notes)
    bonus_melody = [72, 76, 79, 84, 81, 79, 76, 74, 72, 74, 76, 79, 76, 74, 71, 67,
                    69, 72, 76, 81, 79, 76, 74, 72, 67, 71, 74, 79, 77, 74, 71, 67]
    bonus_notes = [(i * .2, note, .28, .16) for i, note in enumerate(bonus_melody)]
    for bar, chord in enumerate([(48, 60, 64, 67), (53, 60, 65, 69), (45, 60, 64, 69), (55, 59, 62, 67)]):
        for beat in range(4):
            bonus_notes.append((bar * 1.6 + beat * .4, chord[beat], .38, .13))
    render("bonus.wav", 6.4, bonus_notes)
    print("AUDIO_OK: six original mono PCM WAVs at 22050 Hz")


if __name__ == "__main__":
    main()
