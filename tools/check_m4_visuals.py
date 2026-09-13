from pathlib import Path
from PIL import Image,ImageChops
import json
root=Path(__file__).resolve().parents[1]
r=root/'records/m4-review01'
result={}
for material,old,stages in [('cardboard','review02',['before','buckling','folding','after']),('aluminum','m2-review01',['before','dent','buckling','folding','compacted','after']),('tire','m3-review01',['before','moderate','maximum','return-start','rebounding','after'])]:
 for view in ['front','side']:
  for stage in stages:
   name=f'{view}-{stage}.png'
   a=Image.open(root/'records'/old/name).convert('RGB')
   b=Image.open(r/f'{material}-regression'/name).convert('RGB')
   result[f'{material}/{name}']=ImageChops.difference(a,b).getbbox() is None
(r/'visual-regression.json').write_text(json.dumps(result,indent=2))
print(f'{sum(result.values())}/{len(result)} screenshots identical')
assert all(result.values())
