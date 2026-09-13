"""Compare the unchanged plastic materials with their accepted screenshots."""
from pathlib import Path
from PIL import Image,ImageChops,ImageStat
import hashlib,json
root=Path(__file__).resolve().parents[1]
records=root/'records/m3-review01'
manifest=json.loads((root/'builds/M2-review-01/source-sha256.json').read_text())
protected=['scripts/cardboard.gd','scripts/crush_solver.gd','scripts/material_profile.gd','scripts/aluminum_can.gd','scripts/aluminum_solver.gd','assets/paper.png','assets/paper-top.png','assets/can-label.png','assets/can-lid.png']
sources={p:hashlib.sha256((root/p).read_bytes()).hexdigest()==manifest[p] for p in protected}
assert all(sources.values())
images={}
for mode,old,stages in [('cardboard','review02',['before','buckling','folding','after']),('aluminum','m2-review01',['before','dent','buckling','folding','compacted','after'])]:
    for view in ['front','side']:
        for stage in stages:
            name=f'{view}-{stage}.png'
            a=Image.open(root/'records'/old/name).convert('RGB')
            b=Image.open(records/f'{mode}-regression'/name).convert('RGB')
            diff=ImageChops.difference(a,b)
            images[f'{mode}/{name}']={'identical':diff.getbbox() is None,'mean_channel_difference':ImageStat.Stat(diff).mean,'bounds':diff.getbbox()}
result={'m1_commit':'b9ac7ee','m2_commit':'7ae3509','protected_sources':sources,'screenshots':images}
(records/'plastic-regression.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps({'sources_identical':all(sources.values()),'screenshots_identical':sum(x['identical'] for x in images.values()),'count':len(images)},indent=2))
