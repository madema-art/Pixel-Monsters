# Milestone 3 original audio

Six instrumental cues were generated locally with the installed YuE2/audio.cpp setup on the RTX 2070 SUPER. No reference recording or existing movie soundtrack was supplied. The direction asks for acoustic orchestra, brass, low strings, timpani and a solemn rising fifth/descending minor-third motif, without vocals or electronic beats.

`tools/score-prompts.json` contains every complete prompt, seed, model, generation setting and CLI argument. Seeds: 3701, 3802, 3903, 4004, 4105, 4206. CUDA device 0; yue2-3b-q4_0.gguf and yue2-vae-f16.gguf; 750–1000 semantic tokens; 16 inference steps; instrumental lyrics tag. All six generation processes completed with exit code 0 and produced 40-second stereo 48 kHz PCM files.

`tools/prepare_audio.py` normalizes levels, overlaps two seconds at the loop boundary, and encodes approximately 38-second Vorbis loops. Original source WAVs remain in the Codex task's `work/m3-score/` folder. The exported assets are in `audio/cinema/`.

The twelve Foley cues are original deterministic synthesis using noise, decaying resonators, short crack transients and distributed clatter impulses. They have distinct spectra/envelopes for punch, hook, kick, headbutt, body impact, footplant, fracture, limb loss, collapse, stagger, clatter and defeat. The source generator is included; RNG seed 3703.

The music controller uses six players but normally only one or two play during a crossfade. Escalation decisions run at 5 Hz; volume smoothing runs each rendered frame. Cues crossfade over 5.5 seconds, hold an eight-second minimum between escalation changes, and only move toward greater intensity until restart. Damage thresholds are 18%, 38% and 60%; simultaneous severe mobility loss can request the desperate state after 30% destruction. After defeat, the current cue holds for two seconds before aftermath. Large impacts briefly duck the score. Pause lowers its volume; slow motion preserves its tempo. M mutes/unmutes music.

Thirty-two positional voices layer impact, fracture, debris, and major-event tails. Volume/pitch variations use a separate seeded RNG and do not affect AI. Spatial attenuation and distance filtering preserve deep impact weight while reducing distant fracture detail. Slow motion limits pitch changes to roughly 0.9–1.0 of normal, plus small variations.

Assets were checked for valid format, nonzero signal, levels, loop preparation and runtime playback/state transitions. Subjective orchestration, repetition and listening balance remain areas for further editorial refinement; generation prompts do not guarantee exact musical instrumentation or motif execution.
