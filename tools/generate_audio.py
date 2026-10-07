import math, random, wave, struct
from pathlib import Path
root = Path(__file__).resolve().parents[1] / 'audio'
root.mkdir(exist_ok=True)
random.seed(41)
for name, seconds in [('impact',1.7),('fracture',1.2)]:
    rate=44100
    samples=[]
    low=0.0
    for i in range(int(rate*seconds)):
        t=i/rate
        n=random.uniform(-1,1)
        low=low*0.95+n*0.05
        if name=='impact':
            boom=math.sin(2*math.pi*(48*t-11*t*t))*math.exp(-3.6*t)
            rumble=low*3.5*math.exp(-2.5*t)
            crack=n*math.exp(-80*t)*0.5
            v=(boom*0.65+rumble*0.32+crack)*min(1,t*300)
        else:
            bursts=sum(math.exp(-45*(t-j*.043)) if t>=j*.043 else 0 for j in range(11))
            v=n*bursts*.13*math.exp(-2*t)+low*.6*math.exp(-4*t)
        samples.append(struct.pack('<h',int(max(-.98,min(.98,v))*32767)))
    with wave.open(str(root/(name+'.wav')),'wb') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(rate); f.writeframes(b''.join(samples))
print('Generated deterministic original impact and fracture WAVs.')
