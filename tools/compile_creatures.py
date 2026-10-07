"""Compile Blender region volumes into exactly 1000 connected, unique body cells."""
import json, heapq, hashlib
from pathlib import Path
from collections import Counter
ROOT=Path(__file__).resolve().parents[1]
NEIGHBORS=((1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(0,0,1),(0,0,-1))
def neighbors(p):
    return [tuple(p[i]+d[i] for i in range(3)) for d in NEIGHBORS]
def parent(region):
    core={'abdomen':'chest','pelvis':'abdomen','neck':'chest','head':'neck'}
    if region in core:return core[region]
    side,part=region.split('_',1)
    return {'shoulder':'chest','upper_arm':side+'_shoulder','forearm':side+'_upper_arm','fist':side+'_forearm','thigh':'pelvis','shin':side+'_thigh','foot':side+'_shin'}[part]
def compile_one(path):
    data=json.loads(path.read_text(encoding='utf-8-sig'))
    volumes={v['region']:v for v in data['volumes']}
    occupied={};regional={}
    order=['chest','abdomen','pelvis','neck','head']
    for side in ('left','right'):order += [side+'_'+p for p in ('shoulder','upper_arm','forearm','fist','thigh','shin','foot')]
    for region in order:
        v=volumes[region];center=v['center'];radius=v['radius']
        def score(p):return sum(((p[i]-center[i])/radius[i])**2 for i in range(3))
        if not occupied:seed=tuple(round(x) for x in center)
        else:
            candidates={q for p in regional[parent(region)] for q in neighbors(p) if q not in occupied and q[1]>=1}
            seed=min(candidates,key=lambda q:(score(q),q))
        frontier=[(score(seed),seed)];queued={seed};cells=[]
        while len(cells)<data['allocation'][region]:
            _,p=heapq.heappop(frontier)
            if p in occupied:continue
            occupied[p]=region;cells.append(p)
            for q in neighbors(p):
                if q not in occupied and q not in queued and q[1]>=1:
                    queued.add(q);heapq.heappush(frontier,(score(q),q))
        regional[region]=cells
    assert len(occupied)==1000
    assert Counter(occupied.values())==Counter(data['allocation'])
    reached={next(iter(occupied))};todo=list(reached)
    while todo:
        for q in neighbors(todo.pop()):
            if q in occupied and q not in reached:reached.add(q);todo.append(q)
    assert len(reached)==1000,'Disconnected anatomy'
    data['cells']=[{'cell':list(p),'region':region} for p,region in occupied.items()]
    data['bounds']={'min':[min(p[i] for p in occupied) for i in range(3)],'max':[max(p[i] for p in occupied) for i in range(3)]}
    data['geometry_sha256']=hashlib.sha256(json.dumps(data['cells'],sort_keys=True).encode()).hexdigest()
    output=ROOT/'data/creatures'/f"{data['id']}.json"
    output.write_text(json.dumps(data,indent=2),encoding='utf-8')
    return {'id':data['id'],'cells':1000,'bounds':data['bounds'],'sha256':data['geometry_sha256']}
if __name__=='__main__':
    print(json.dumps([compile_one(p) for p in sorted((ROOT/'art/creatures').glob('*-blender.json'))],indent=2))

