"""Original YuE2 instrumental cues; prompts and exact CLI settings are reproducible."""
import json, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORK = Path(sys.argv[1])
WORK.mkdir(parents=True, exist_ok=True)
COMMON = ('Original instrumental symphonic giant creature cinema score. D minor, 84 BPM, '
          'majestic mythological gravity, large French horns, trombones, cellos and double basses, '
          'timpani, concert bass drum, suspended cymbals, spacious concert hall. '
          'A solemn rising perfect fifth followed by descending minor third as the main motif. '
          'Serious theatrical grandeur, acoustic orchestra, no vocals, no choir, no electronic beat.')
CUES = {
    'opening': 'Ominous quiet opening, low string tremolo, distant restrained horn calls, sparse timpani, slow suspenseful dynamics.',
    'early': 'Two colossal creatures approaching, solemn horns above measured low string ostinato, deliberate orchestral percussion, restrained battle energy.',
    'mid': 'Increasing battle intensity, bold brass motif, rolling timpani, driving low strings, powerful but stately orchestral momentum.',
    'severe': 'Tragic destructive battle, dark brass chords, urgent string ostinatos, enormous bass drum and cymbal swells, dramatic harmonic tension.',
    'desperate': 'Full epic orchestra at peak intensity, defiant horn motif, thunderous timpani, urgent bowed strings, terrifying majestic grandeur.',
    'aftermath': 'Solemn tragic resolution, broad sustained horn elegy, low strings settle into a quiet D minor cadence, percussion fades, long spacious ending.'
}
settings = {'model': 'yue2-3b-q4_0.gguf', 'vae': 'yue2-vae-f16.gguf', 'backend':'cuda',
            'min_tokens':750, 'max_tokens':1000, 'steps':16, 'cot':'off'}
manifest = []
for i, (name, direction) in enumerate(CUES.items()):
    prompt = COMMON + ' ' + direction
    args = ['D:/YuE2/audio.cpp/audiocpp_cli.exe', '--task','gen','--family','yue2',
            '--model','D:/YuE2/models','--backend','cuda','--device','0','--threads','8',
            '--session-option','yue2.model_gguf='+settings['model'],
            '--session-option','yue2.vae_gguf='+settings['vae'], '--lyrics','[Instrumental]',
            '--request-option','style='+prompt,'--request-option','cot=off',
            '--request-option','semantic_min_tokens=750','--request-option','semantic_max_tokens=1000',
            '--request-option','num_inference_steps=16','--seed',str(3701+i*101),
            '--out',str(WORK/(name+'.wav')),'--log','--metrics']
    entry = {'cue':name,'prompt':prompt,'seed':3701+i*101,'settings':settings,'arguments':args}
    manifest.append(entry)
    (ROOT/'tools/score-prompts.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    if (WORK/(name+'.wav')).exists(): continue
    print('Generating '+name, flush=True)
    with (WORK/(name+'.log')).open('w',encoding='utf-8') as log:
        result = subprocess.run(args,cwd='D:/YuE2/audio.cpp',stdout=log,stderr=subprocess.STDOUT)
    entry['exit_code']=result.returncode
    (ROOT/'tools/score-prompts.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    print(name+' exit '+str(result.returncode),flush=True)
    if result.returncode: break
