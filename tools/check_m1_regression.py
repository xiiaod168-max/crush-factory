"""Compare accepted cardboard evidence against final M2 cardboard mode."""
from pathlib import Path
from PIL import Image, ImageChops, ImageStat
import hashlib,json
root=Path(__file__).resolve().parents[1]
records=root/'records/m2-review01'
baseline=json.loads((root/'builds/M1-review-02/source-sha256.json').read_text())
protected=['scripts/cardboard.gd','scripts/crush_solver.gd','scripts/material_profile.gd','assets/paper.png','assets/paper-top.png']
source={p:hashlib.sha256((root/p).read_bytes()).hexdigest()==baseline[p] for p in protected}
assert all(source.values()),'Accepted cardboard implementation changed'
images={}
for view in ['front','side']:
    for stage in ['before','buckling','folding','after']:
        name=f'{view}-{stage}.png'
        a=Image.open(root/'records/review02'/name).convert('RGB')
        b=Image.open(records/'cardboard-regression'/name).convert('RGB')
        diff=ImageChops.difference(a,b)
        images[name]={'identical':diff.getbbox() is None,'mean_channel_difference':ImageStat.Stat(diff).mean,'bounds':diff.getbbox()}
result={'baseline_commit':'b9ac7ee','protected_sources_identical':source,'screenshots':images}
(records/'cardboard-regression.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result,indent=2))
