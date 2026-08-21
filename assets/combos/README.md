# Combo Trainer voice clips

One WAV per combo. The app plays `combos/<digits>.wav` for each announced combo
(e.g. combo [1,2,3] → `1_2_3.wav`); if a clip is missing it falls back to the
device TTS voice.

The current clips were generated offline from the macOS "Daniel" voice
(`say -v Daniel -r 170` → `afconvert -f WAVE -d LEI16`), so they are clear and
identical on every device. To swap in a different voice, regenerate the same
12 files (same names) — e.g. with a premium AI voice — and keep them WAV/MP3.

Punch numbering: 1 Jab · 2 Cross · 3 Lead Hook · 4 Rear Hook ·
5 Lead Uppercut · 6 Rear Uppercut.

| File | Phrase |
|------|--------|
| `1_2.wav`      | Jab, Cross |
| `1_1_2.wav`    | Jab, Jab, Cross |
| `1_2_3.wav`    | Jab, Cross, Lead Hook |
| `1_2_3_2.wav`  | Jab, Cross, Lead Hook, Cross |
| `2_3_2.wav`    | Cross, Lead Hook, Cross |
| `1_6.wav`      | Jab, Rear Uppercut |
| `3_2.wav`      | Lead Hook, Cross |
| `1_2_5_2.wav`  | Jab, Cross, Lead Uppercut, Cross |
| `1_1.wav`      | Jab, Jab |
| `1_2_3_6.wav`  | Jab, Cross, Lead Hook, Rear Uppercut |
| `6_3_2.wav`    | Rear Uppercut, Lead Hook, Cross |
| `1_4.wav`      | Jab, Rear Hook |
