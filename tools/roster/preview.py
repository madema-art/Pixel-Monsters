"""Quick silhouette sheet (front / side / three-quarter) of compiled roster bodies. Usage: preview.py out.png id [id...]"""
import json, sys, math, colorsys
from pathlib import Path
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parents[2]

def shade(i):
    h = (hash(i) % 997) / 997.0
    return tuple(int(255*c) for c in colorsys.hsv_to_rgb(h, 0.45, 0.85))

def render(data, view, size=360):
    cells = data["cells"]
    pts = []
    for e in cells:
        x, y, z = e["cell"]
        if view == "front": u, v, d = x, y, -z
        elif view == "side": u, v, d = z, y, x
        else:
            a = math.radians(35); u = x*math.cos(a) - z*math.sin(a); d = -(x*math.sin(a) + z*math.cos(a)); v = y
        pts.append((u, v, d, e["region"]))
    us = [p[0] for p in pts]; vs = [p[1] for p in pts]
    sc = (size-30) / max(max(vs)-min(vs)+2, max(us)-min(us)+2)
    img = Image.new("RGB", (size, size), (30, 34, 42)); dr = ImageDraw.Draw(img)
    for u, v, d, r in sorted(pts, key=lambda p: p[2]):
        px = size/2 + (u - (max(us)+min(us))/2) * sc; py = size-12 - (v - min(vs)) * sc
        c = shade(r); k = max(0.55, 1-0.02*(d-min(p[2] for p in pts)))
        dr.rectangle([px-sc*0.47, py-sc*0.47, px+sc*0.47, py+sc*0.47], fill=tuple(int(x*k) for x in c))
    return img

out = sys.argv[1]; ids = sys.argv[2:]
sheet = Image.new("RGB", (360*3, 360*len(ids)))
for row, i in enumerate(ids):
    d = json.load(open(ROOT/"data/creatures"/f"{i}.json"))
    for col, v in enumerate(("front", "side", "three")):
        sheet.paste(render(d, v), (col*360, row*360))
sheet.save(out)
