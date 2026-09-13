from pathlib import Path
import json,hashlib,shutil,zipfile
from collections import Counter
r=Path(__file__).resolve().parents[1]; d=r/'records/m4-review01'; b=r/'builds/M4-review-01'
v=json.loads((d/'gameplay-verify.json').read_text()); s=json.loads((d/'gameplay-session.json').read_text()); t=json.loads((d/'gameplay-resume.json').read_text()); images=json.loads((d/'visual-regression.json').read_text())
assert not v['failures'] and not s['failures'] and not t['failures']
assert Counter(x['object'] for x in v['cycles'])=={'cardboard':5,'aluminum':5,'tire':5}
assert s['pid']!=t['pid'] and s['money']==t['money']==83 and t['phase']=='SELECT'
assert all(images.values())
p=v['performance']; sha=hashlib.sha256((b/'CrushFactory.exe').read_bytes()).hexdigest()
report=f'''# M4 Gameplay Review 01

状态：开发交付，等待用户 Gameplay 验收；未创建 M4 验收 commit。M3 已验收稳定提交：207ef8d。

## 游戏循环
免费选择物品 → PRESS/PAUSE → RETURN → 等待卸载与轮胎回弹 → 查看评价 → COLLECT → 40 金币购买 Level 2 → 压力 80 提高到 100、解锁轮胎。新档 0 金币，纸箱与铝罐开放。

结算使用 Base × Difficulty × (0.25 + 0.75 × Peak Compression)，四舍五入；达到材质目标的 85% 加 Bonus。零形变零奖励。轮胎按峰值计奖，另显示回弹后的最终高度。数值详见 README_M4.md。

## 最终 EXE 测试
- 十组自动测试通过：纸箱四组、铝罐两组、轮胎两组、经济存档一组、生命周期一组。
- 三种材料各 5 个完整 Gameplay 周期，共 15 次：选择、压缩、回程、卸载、结算、领取、磁盘读取确认均通过。
- 防护：未归位/未结算不能换物；卸载中不能领；领取不能重复；收集后不能再次压同物；升级只能购买一次；暂停、提前回程、零奖励、保存失败回滚、中途退出恢复、声音设置恢复均测试。
- 实际铝罐压缩率：Lv1 {v['cycles'][1]['peak']*100:.2f}% → Lv2 {v['cycles'][3]['peak']*100:.2f}%。压力升级改变真实求解能力。
- 10 个已验收形变/压板/音效源码与 M3 一致；同版本 Godot 直接运行旧验收场景，对照纸箱 8 张、铝罐 12 张、轮胎 12 张双视角阶段图，共 32 张逐像素一致。
- 15 轮检查失败 0；最终运行、回归和测试日志检查无 ERROR/WARNING。早期预览/红测失败记录仅留开发目录，不装入交付证据。发布模板禁止命令行覆盖场景路径，因此双视角对照采用同版本 Godot 标准版直接运行相同源码；15 轮循环、性能与 Gameplay 录像均来自最终 EXE。

## 完整 Gameplay 录像及真实重启
gameplay-full.mp4 包含 96.17 秒完整新游戏流程与 6.67 秒重启后验证，约 102.83 秒。通过正常 UI 信号自动操作，画面与音轨由最终 EXE Movie Maker 输出；该固定 30fps 录制不用于性能结论。
先运行 PID {s['pid']}，正常退出、退出码 0，再启动同一个 EXE 的 PID {t['pid']}。两个真实进程段直接拼接，只有退出/重启处一处剪接，无伪造重载。重启后保留 83 金币、Level 2、轮胎解锁，场景回到 SELECT，不能再领取旧奖励。
视频包含纸箱 +28、铝罐 +16、升级 -40、轮胎 +79。测试使用独立存档，不覆盖玩家正常存档。

## 性能
最终 EXE，Intel UHD，1280×720，Compatibility；独立 15 轮实际运行、不录制、不使用固定帧率，预热 2 秒后记录 {p['frames']} 帧。
平均 {p['average_fps']:.2f} FPS；P95 {p['p95_ms']:.2f}ms；P99 {p['p99_ms']:.2f}ms；最长帧 {p['max_ms']:.2f}ms。达到 720p 最低目标，但不声称每帧均达 60 FPS。

## 版本与已知问题
版本 0.4.0-m4-review.1。EXE SHA256：{sha}。
只有两个压力等级，三个免费物品，经济数值为 MVP；英文简洁工业 UI；无云存档、无手动编辑存档防作弊；未保存中途物品/未领取结算，退出会放弃该次物品；可执行文件未签名。损坏存档会保留原文件并提示，当前没有游戏内存档修复界面。
M1/M2/M3 Polish Backlog 不阻塞本轮且未实施。M4 已停在 Gameplay 验收门槛，不增加第四物品或后续内容。
'''
(d/'M4_REVIEW.md').write_text(report,encoding='utf-8')
(b/'M4_REVIEW.md').write_text(report,encoding='utf-8')
e=b/'evidence'; e.mkdir(exist_ok=True)
for name in ['gameplay-full.mp4','gameplay-session.json','gameplay-resume.json','gameplay-verify.json','visual-regression.json','protected-sources.json','video-info.json','audio-validation.log','gameplay-session.log','gameplay-restart.log','gameplay-verify.log']:
 shutil.copy2(d/name,e/name)
for path in d.glob('*.png'): shutil.copy2(path,e/path.name)
for path in d.glob('*_test.log*'): shutil.copy2(path,e/path.name)
for m in ['cardboard','aluminum','tire']:
 shutil.copytree(d/f'{m}-regression',e/f'{m}-regression',dirs_exist_ok=True)
manifest={str(x.relative_to(b)):hashlib.sha256(x.read_bytes()).hexdigest() for x in b.rglob('*') if x.is_file() and x.name!='artifact-sha256.json'}
(b/'artifact-sha256.json').write_text(json.dumps(manifest,indent=2))
sources={str(x.relative_to(r)):hashlib.sha256(x.read_bytes()).hexdigest() for folder in ['scripts','scenes','assets'] for x in (r/folder).rglob('*') if x.is_file()}
(b/'source-sha256.json').write_text(json.dumps(sources,indent=2))
manifest['source-sha256.json']=hashlib.sha256((b/'source-sha256.json').read_bytes()).hexdigest()
(b/'artifact-sha256.json').write_text(json.dumps(manifest,indent=2))
z=r/'builds/CrushFactory-M4-review-01-Windows-x64.zip'
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as out:
 for x in b.rglob('*'):
  if x.is_file(): out.write(x,x.relative_to(b))
with zipfile.ZipFile(z) as out: assert out.testzip() is None
print(json.dumps({'zip':str(z),'exe_sha256':sha,'performance':p,'cycles':len(v['cycles']),'visual_matches':len(images)},indent=2))
