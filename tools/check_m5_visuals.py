from pathlib import Path
from PIL import Image,ImageChops
import json
root=Path(__file__).resolve().parents[1]; r=root/'records/m5-review01'; result={}
for material,old,stages in [('cardboard','review02',['before','buckling','folding','after']),('aluminum','m2-review01',['before','dent','buckling','folding','compacted','after']),('tire','m3-review01',['before','moderate','maximum','return-start','rebounding','after'])]:
 for view in ['front','side']:
  for stage in stages:
   name=f'{view}-{stage}.png'
   a=Image.open(root/'records'/old/name).convert('RGB'); b=Image.open(r/f'{material}-regression'/name).convert('RGB')
   diff=ImageChops.difference(a,b)
   result[f'{material}/{name}']={'full_identical':diff.getbbox() is None,'scene_identical':diff.crop((0,0,1280,600)).getbbox() is None,'difference_bounds':diff.getbbox()}
(r/'visual-regression.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
assert all(x['scene_identical'] for x in result.values())
print(f"PASS: {sum(x['scene_identical'] for x in result.values())}/32 scene regions identical; {sum(x['full_identical'] for x in result.values())}/32 full frames identical. Any remaining differences are below y=600 in legacy controls.")
