"""Prepare original YuE2 score loops and original procedural material Foley."""
from pathlib import Path
import sys, subprocess, wave
import numpy as np

root=Path(__file__).resolve().parents[1]
out=root/'audio'/'cinema';out.mkdir(parents=True,exist_ok=True)
source=Path(sys.argv[1]); rate=48000
for cue in ['opening','early','mid','severe','desperate','aftermath']:
    # Match loudness, overlap the endpoints to avoid a discontinuity on repeat.
    with wave.open(str(source/(cue+'.wav'))) as f:
        data=np.frombuffer(f.readframes(f.getnframes()),dtype='<i2').reshape(-1,f.getnchannels()).astype(np.float64)/32768
    n=rate*2
    ramp=np.linspace(0,1,n)[:,None]
    loop=np.concatenate([data[n:-n],data[-n:]*(1-ramp)+data[:n]*ramp])
    rms=np.sqrt(np.mean(loop**2));loop*=min(0.12/max(rms,1e-6),0.94/max(np.max(np.abs(loop)),1e-6))
    tmp=out/(cue+'.wav')
    with wave.open(str(tmp),'w') as f:
        f.setnchannels(2);f.setsampwidth(2);f.setframerate(rate);f.writeframes((loop*32767).astype('<i2').tobytes())
    subprocess.run(['ffmpeg','-y','-hide_banner','-loglevel','error','-i',str(tmp),'-c:a','libvorbis','-q:a','5',str(out/(cue+'.ogg'))],check=True)
    tmp.unlink()

rng=np.random.default_rng(3703)
def foley(name,seconds,tones,crack,tail,clatters=0):
    t=np.arange(int(rate*seconds))/rate
    noise=rng.normal(0,1,len(t)); filtered=np.convolve(noise,np.ones(21)/21,'same')
    x=np.zeros(len(t))
    for hz,decay,gain in tones:
        x+=gain*np.sin(2*np.pi*(hz*t+hz*0.018*(1-np.exp(-t*20))))*np.exp(-t/decay)
    x+=crack*noise*np.exp(-t/0.018)+tail*filtered*np.exp(-t/0.48)
    for i in range(clatters):
        offset=int(rate*rng.uniform(0.09,seconds*0.82)); tt=t[:len(t)-offset]
        x[offset:]+=rng.uniform(.025,.08)*np.sin(2*np.pi*rng.uniform(480,1600)*tt)*np.exp(-tt/.025)
    x*=np.minimum(1,t/.003);x*=np.minimum(1,(seconds-t)/.05)
    x*=.90/max(np.max(np.abs(x)),1e-6)
    with wave.open(str(out/(name+'.wav')),'w') as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes((x*32767).astype('<i2').tobytes())
foley('punch',.8,[(78,.22,.7),(154,.1,.22)],.32,.28)
foley('hook',1.4,[(44,.48,.8),(91,.19,.32)],.48,.55)
foley('kick',1.2,[(55,.36,.8),(120,.16,.24)],.64,.42)
foley('head',.95,[(105,.24,.6),(263,.1,.3)],.8,.25)
foley('body',1.6,[(34,.62,.9),(69,.32,.38)],.22,.6)
foley('foot',1.15,[(39,.38,.8),(88,.14,.2)],.17,.48,7)
foley('fracture',1.05,[(420,.08,.16),(760,.055,.12)],.95,.7,15)
foley('limb',2.3,[(48,.62,.8),(130,.17,.2)],.7,.7,32)
foley('collapse',3.5,[(28,.92,.8),(61,.5,.4)],.56,.9,70)
foley('stagger',.8,[(52,.26,.8)],.12,.55,4)
foley('clatter',1.8,[(610,.035,.2)],.23,.2,28)
foley('defeat',2.8,[(29,.85,.8),(115,.6,.1)],.12,.7)
print('Six original score loops and twelve distinct original Foley layers prepared.')
