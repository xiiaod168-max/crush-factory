from pathlib import Path
import subprocess,hashlib,json
root=Path(__file__).resolve().parents[1]
paths=['scripts/main.gd','scripts/press_controller.gd','scripts/cardboard.gd','scripts/crush_solver.gd','scripts/material_profile.gd','scripts/aluminum_can.gd','scripts/aluminum_solver.gd','scripts/tire.gd','scripts/rubber_solver.gd','scripts/press_audio.gd']
result={p:hashlib.sha256((root/p).read_bytes()).hexdigest()==hashlib.sha256(subprocess.check_output(['git','show','207ef8d:'+p],cwd=root)).hexdigest() for p in paths}
# Git stores LF; compare normalized text on Windows.
result={p:(root/p).read_text()==subprocess.check_output(['git','show','207ef8d:'+p],cwd=root).decode() for p in paths}
assert all(result.values())
(root/'records/m4-review01/protected-sources.json').write_text(json.dumps({'baseline':'207ef8d','unchanged':result},indent=2))
print('PASS: all 10 accepted deformation/control/audio sources unchanged')
