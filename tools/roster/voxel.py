"""Procedural volume -> exactly-1000-cube compiler for the tournament roster.

Regions are unions of ellipsoids ('e') / boxes ('b'). Every lattice cell is claimed by the region whose
volume it fits best (Voronoi-style). A global radius scale is bisected until at least 1000 cells exist,
then the outermost cells are trimmed (connectivity-preserving) to exactly 1000.
"""
import hashlib, json, math
from collections import Counter, deque

NB = ((1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(0,0,1),(0,0,-1))

def E(cx,cy,cz,rx,ry=None,rz=None):
    ry = rx if ry is None else ry; rz = rx if rz is None else rz
    return ('e',cx,cy,cz,rx,ry,rz)

def B(cx,cy,cz,hx,hy=None,hz=None):
    hy = hx if hy is None else hy; hz = hx if hz is None else hz
    return ('b',cx,cy,cz,hx,hy,hz)

def cap(p0,p1,r,squash=1.0):
    """Chain of overlapping spheres between two points (isotropic radius r, optional z squash)."""
    d = math.dist(p0,p1)
    n = max(1,int(d/(r*0.6)))
    out = []
    for i in range(n+1):
        t = i/n
        out.append(E(*(p0[k]+(p1[k]-p0[k])*t for k in range(3)), r, r, r*squash))
    return out

def score(v,q,s):
    t,cx,cy,cz,rx,ry,rz = v
    cx,cy,cz = cx*s,1+(cy-1)*s,cz*s
    dx,dy,dz = (q[0]-cx)/(rx*s),(q[1]-cy)/(ry*s),(q[2]-cz)/(rz*s)
    if t=='e': return dx*dx+dy*dy+dz*dz
    m = max(abs(dx),abs(dy),abs(dz)); return m*m

def claim(regions, s):
    """regions: {name:{'vols':[...],'w':bias}} -> {cell:(region,score)}"""
    lo = [1e9]*3; hi=[-1e9]*3
    for r in regions.values():
        for v in r['vols']:
            for k in range(3):
                ext = v[4+k]*s*1.05
                c = v[1+k]*s if k!=1 else 1+(v[2]-1)*s
                lo[k]=min(lo[k],c-ext); hi[k]=max(hi[k],c+ext)
    cells={}
    for x in range(math.floor(lo[0]),math.ceil(hi[0])+1):
        for y in range(max(1,math.floor(lo[1])),math.ceil(hi[1])+1):
            for z in range(math.floor(lo[2]),math.ceil(hi[2])+1):
                best=None
                for name,r in regions.items():
                    w=r.get('w',1.0)
                    for v in r['vols']:
                        sc=score(v,(x,y,z),s)*w
                        if sc<=1.0 and (best is None or sc<best[1]): best=(name,sc)
                if best: cells[(x,y,z)]=best
    return cells

def components(cells):
    seen=set(); comps=[]
    for c in cells:
        if c in seen: continue
        comp=[c]; seen.add(c); dq=deque([c])
        while dq:
            p=dq.popleft()
            for d in NB:
                q=(p[0]+d[0],p[1]+d[1],p[2]+d[2])
                if q in cells and q not in seen: seen.add(q); comp.append(q); dq.append(q)
        comps.append(comp)
    return comps

def repair(live, regions_of):
    """Join stray components with short chains of real body cells (no hidden bridge cubes)."""
    while True:
        comps=components(set(live))
        if len(comps)==1: return live
        comps.sort(key=len)
        small=comps[0]; main=set(c for comp in comps[1:] for c in comp)
        seen={c:None for c in small}; dq=deque(small)
        found=None
        while dq and found is None:
            p=dq.popleft()
            for d in NB:
                q=(p[0]+d[0],p[1]+d[1],p[2]+d[2])
                if q in seen or q[1]<1: continue
                seen[q]=p
                if q in main: found=q; break
                dq.append(q)
        assert found is not None
        # walk back to the small component; fill path cells with the region of the cell they grew from
        path=[]; cur=seen[found]
        while cur is not None and cur not in live:
            path.append(cur); cur=seen[cur]
        owner=live[cur][0] if cur in live else None
        for c in path: live[c]=(owner,0.99)
    return live

def compile_regions(regions, target=1000, expect_components=1, max_trim_fraction=0.35, min_region=4):
    lo,hi=0.4,3.0
    margin=20 if expect_components==1 else 0
    for _ in range(22):
        mid=(lo+hi)/2
        if len(claim(regions,mid))>=target-margin: hi=mid
        else: lo=mid
    s=hi
    for attempt in range(12):
        cells=claim(regions,s)
        live=dict(cells)
        if expect_components==1: live=repair(live,None)
        if len(live)>=target: break
        s*=1.01
    counts=Counter(v[0] for v in live.values())
    base=dict(counts)
    removable=sorted(live.items(), key=lambda kv:-kv[1][1])
    excess=len(live)-target
    ncomp=len(components(set(live)))
    for cell,(name,sc) in removable:
        if excess<=0: break
        if counts[name]<=max(min_region,base[name]*(1-max_trim_fraction)): continue
        del live[cell]
        if len(components(set(live)))!=ncomp:
            live[cell]=(name,sc); continue
        counts[name]-=1; excess-=1
    assert excess<=0, ("could not trim to target",excess)
    assert len(live)==target,(len(live),target)
    comps=components(set(live))
    assert len(comps)==expect_components,("components",len(comps),[len(c) for c in comps])
    return live,s

def sp(p,s):
    return [round(p[0]*s,3),round(1+(p[1]-1)*s,3),round(p[2]*s,3)]

def scale_design(spec,s):
    """Anchors authored in design space are scaled by the same factor the volumes were fitted with."""
    rig={k:(sp(v,s) if isinstance(v,list) and len(v)==3 else v) for k,v in spec.get('rig',{}).items()}
    spec['rig']=rig
    for e in spec.get('extras',[]):
        e['pivots']=[sp(p,s) for p in e['pivots']]
        if 'tip' in e: e['tip']=sp(e['tip'],s)
    for key_t,tip in spec.get('tips',{}).items(): tip['point']=sp(tip['point'],s)
    for key in ('legs_rig','limb_rig'):
        if key in spec:
            for limb in spec[key]:
                for k in ('root','mid','end','idle'):
                    if k in limb: limb[k]=sp(limb[k],s)
    return spec

def slim_regions(regions,slim):
    if slim==1.0: return regions
    out={}
    for n,r in regions.items():
        vols=[(v[0],v[1],v[2],v[3],v[4]*slim,v[5]*slim,v[6]*slim) for v in r['vols']]
        out[n]=dict(r,vols=vols)
    return out

def finish(spec, live, s, regions):
    spec=scale_design(dict(spec),s)
    majors={n:r.get('major',n) for n,r in regions.items()}
    order=list(regions.keys())
    cells=[]
    for c,(name,_) in sorted(live.items(), key=lambda kv:(order.index(kv[1][0]),kv[0][1],kv[0][0],kv[0][2])):
        entry={"cell":list(c),"region":name,"major":majors[name]}
        cells.append(entry)
    spec_tags=spec.get('tags') or {}
    for entry in cells:
        t=spec_tags.get(tuple(entry["cell"]))
        if t: entry["tag"]=t
    alloc=Counter(e["region"] for e in cells)
    data={k:v for k,v in spec.items() if k not in ('regions','tags','expect_components')}
    data["allocation"]={n:alloc[n] for n in order}
    data["majors"]=majors
    data["cells"]=cells
    xs=[e["cell"] for e in cells]
    data["bounds"]={"min":[min(c[i] for c in xs) for i in range(3)],"max":[max(c[i] for c in xs) for i in range(3)]}
    data["fit_scale"]=round(s,3)
    data["geometry_sha256"]=hashlib.sha256(json.dumps(cells,sort_keys=True).encode()).hexdigest()
    return data

def front_cell(live, region, x, y):
    """Front-most (min z) cell of region at lattice column (x,y)."""
    zs=[c[2] for c,(n,_) in live.items() if n==region and c[0]==x and c[1]==y]
    return (x,y,min(zs)) if zs else None
