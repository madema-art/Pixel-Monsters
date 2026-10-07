"""Compile roster specs into data/creatures/<id>.json. Usage: python tools/roster/compile_roster.py [id ...]"""
import json, sys, importlib
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import voxel

ROOT = Path(__file__).resolve().parents[2]
MODULES = ["specs_tier1","specs_tier2","specs_tier3","specs_tier4"]

def all_specs():
    out = {}
    for name in MODULES:
        try:
            mod = importlib.import_module(name)
        except ModuleNotFoundError:
            continue
        for spec in mod.SPECS:
            out[spec["id"]] = spec
    return out

def build(spec):
    regions = voxel.slim_regions(spec["regions"], spec.get("slim", 1.0))
    live, s = voxel.compile_regions(regions, expect_components=spec.get("expect_components", 1))
    if "tags_fn" in spec:
        spec = dict(spec); spec["tags"] = spec.pop("tags_fn")(live)
    data = voxel.finish({k: v for k, v in spec.items() if k != "tags_fn"}, live, s, regions)
    out = ROOT / "data/creatures" / f"{spec['id']}.json"
    out.write_text(json.dumps(data, indent=1), encoding="utf-8")
    return data

if __name__ == "__main__":
    specs = all_specs()
    wanted = sys.argv[1:] or list(specs)
    for sid in wanted:
        d = build(specs[sid])
        b = d["bounds"]
        print(f"{sid:20s} cells={len(d['cells'])} scale={d['fit_scale']} size={[b['max'][i]-b['min'][i]+1 for i in range(3)]} regions={len(d['allocation'])}")
