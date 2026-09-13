from pathlib import Path
import subprocess,json,hashlib
r=Path(__file__).resolve().parents[1]
paths=['scripts/main.gd','scripts/cardboard.gd','scripts/crush_solver.gd','scripts/material_profile.gd','scripts/aluminum_can.gd','scripts/aluminum_solver.gd','scripts/tire.gd','scripts/rubber_solver.gd','scripts/press_audio.gd','scripts/progress.gd']
checks={p:(r/p).read_text(encoding='utf-8')==subprocess.check_output(['git','show','1c4165e:'+p],cwd=r).decode('utf-8') for p in paths}
assert all(checks.values())
(r/'records/m5-review01/protected-sources.json').write_text(json.dumps({'baseline':'1c4165e','unchanged':checks},indent=2),encoding='utf-8')
print('PASS 10 protected material, economy, audio and base-scene sources unchanged')
