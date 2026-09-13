from pathlib import Path
import json,hashlib,shutil,zipfile
from collections import Counter
r=Path(__file__).resolve().parents[1]; d=r/'records/m5-review01'; b=r/'builds/M5-review-01'
v=json.loads((d/'gameplay-verify.json').read_text(encoding='utf-8')); s=json.loads((d/'gameplay-session.json').read_text(encoding='utf-8')); t=json.loads((d/'gameplay-resume.json').read_text(encoding='utf-8')); images=json.loads((d/'visual-regression.json').read_text(encoding='utf-8'))
assert not v['failures'] and not s['failures'] and not t['failures']
assert Counter(x['object'] for x in v['cycles'])=={'cardboard':5,'aluminum':5,'tire':5}
assert s['pid']!=t['pid'] and s['money']==t['money']==83 and t['phase']=='SELECT'
assert all(x['scene_identical'] for x in images.values())
p=v['performance']; sha=hashlib.sha256((b/'CrushFactory.exe').read_bytes()).hexdigest()
report=f'''# M5 Vertical Slice / Game Feel Review 01

交付状态：等待用户视觉验收。M4 已验收稳定提交 1c4165e；原 Windows Build、ZIP、Gameplay 视频与证据保留。

## 这次改变
- 远处快进（最高约 1.7 单位/秒），距离物品 0.16 时回到 0.34 的接触接近速度；接触后的求解速度、阻力曲线、结构停顿与释放均保持不变。回程从 0.65 提高到 1.65。
- 对照原 60Hz 控制器：初次接触从 123 帧 / 2.05 秒减至 47 帧 / 0.78 秒；纸箱/铝罐满压回程 185 → 73 帧，即 3.08 → 1.22 秒。两项空载时间合计减少约 61%，每轮省 3.13 秒。轮胎回程 153 → 61 帧。
- 三材料接触形变序列与旧节奏逐物理步比较，最大偏差约 1e-14；没有用加速 deformation 换取节奏提升。低等级纸箱的承压过程仍然较长，此次保留该材料时间曲线。
- Player HUD 仅显示金币、等级、当前物品、压缩率与下一步；F3 打开详细调试信息。底部一个黄色主操作随状态切换，次要操作降权。
- 保存成功后触发 +COINS、0.65 秒金币递增、短促机械确认音；失败不播放到账反馈。PRESS UPGRADED 与 NEW OBJECT UNLOCKED 分成两个阶段，提供轮胎轮廓与 TRY THE TIRE。
- 原创程序化混凝土/墙面/漆面/油污，增加少量管线、电缆、警示牌、液压动力箱与状态灯。降低背景亮度，保留重点光、冷暖层次和一组方向阴影。Compatibility 基线不变。

## 回归与测试
- 13 组测试通过：原材料/控制器/存档/循环测试，加节奏对照、M5 交互测试及引擎鼠标/键盘路由测试；另补充铝罐、轮胎节奏对照。
- 引擎内鼠标命中、Space 暂停、F3、R/C 快捷键和重复领取已通过；1024×576 画面已检查。修复 Space 按下/抬起重复响应焦点按钮的问题。OS 级输入工具应用授权超时，未完成 SendInput 测试；范围见 manual-input.md。
- 最终 EXE 三材料各 5 次，共 15 个完整循环，失败 0。包含奖励单领、真实磁盘读回、解锁、压力升级及轮胎回弹。
- 最终测试和运行日志无 ERROR/WARNING。旧材料/经济/音效/基础场景 10 个源码文件与 M4 一致。公共控制器仅增加可选空载速度参数，旧 Demo 默认关闭。
- 同版 Godot 运行旧验收场景，纸箱 8、铝罐 12、轮胎 12，32 张物品/机器画面区域均与原验收图逐像素一致；31 张全图一致，铝罐正面回程图仅旧 NEW CAN 按钮的鼠标悬停外观不同（差异矩形 x370–525 / y618–660），材料和机器画面无差异。发布模板不支持命令行指定旧场景，因此旧图对照来自标准版；游戏循环、视频和性能来自最终 EXE。
- 铝罐 Lv1 峰值 {v['cycles'][1]['peak']*100:.2f}% → Lv2 {v['cycles'][3]['peak']*100:.2f}%，实际机器能力仍然显著不同。
- 最终 Gameplay 视频约 100.30 秒，其中主体约 93.63 秒，含奖励、升级、解锁、轮胎压缩及回弹；另有真实退出后重启的 6.67 秒验证。进程 {s['pid']} → {t['pid']}，83 金币、Level 2、轮胎解锁正确恢复，不能重复领取。
- 录像通过真实 UI 信号驱动，最终 EXE Movie Maker 输出画面和音轨；固定 30fps，仅用于视觉验收。两个实际进程段在退出/重启处拼接，不伪造重载。

## 性能
Intel UHD / 1280×720 / Compatibility。最终 EXE，无录制、无固定帧率，预热 2 秒，采集 {p['frames']} 帧。
平均 **{p['average_fps']:.2f} FPS**；P95 **{p['p95_ms']:.2f}ms**；P99 **{p['p99_ms']:.2f}ms**；最长 **{p['max_ms']:.2f}ms**。不声称每帧稳定 60 FPS。
M4 参考平均 58.04 FPS / P95 20.84ms；两次为独立实测，不作为严格同机同时 A/B 性能统计。

## 文件与范围
版本 0.5.0-m5-review.1。EXE SHA256：{sha}。
CrushFactory.exe 可双击运行；README.md 为操作说明，evidence 保存视频、截图、结果与日志。图形纹理、图标和新增机械提示音均为原创程序化资源，许可见 ASSET_LICENSES.md。
已知限制：仅三物品、两级压力、英文 HUD；无云存档、手动改档防护或存档修复页面；未签名 EXE；中途退出放弃未领取物品；工业美术仍为小型 Vertical Slice，不是最终商业资产。已验收材料的 Polish Backlog 未在此轮擅自修改。
M5 未创建验收 commit，完成交付后暂停，不增加第四物品、复杂经营或 Steam API。
'''
(d/'M5_REVIEW.md').write_text(report,encoding='utf-8'); (b/'M5_REVIEW.md').write_text(report,encoding='utf-8')
for name in ['DEVELOPMENT_PLAN.md','DESIGN.md','README_M5.md','ASSET_LICENSES.md']:
 shutil.copy2(r/name,b/('README.md' if name=='README_M5.md' else name))
e=b/'evidence'; e.mkdir(exist_ok=True)
for name in ['gameplay-full.mp4','gameplay-session.json','gameplay-resume.json','gameplay-verify.json','visual-regression.json','protected-sources.json','video-info.json','audio-validation.log','gameplay-session.log','gameplay-restart.log','gameplay-verify.log','ui-static-audit.json','input-dispatch.log','input-dispatch.json']:
 shutil.copy2(d/name,e/name)
for path in list(d.glob('*.png'))+list(d.glob('*_test.log*'))+list(d.glob('cadence-aluminum.log'))+list(d.glob('cadence-tire.log'))+list(d.glob('manual-*')):
 if path.is_file() and not path.stem.endswith('-diff'): shutil.copy2(path,e/path.name)
for m in ['cardboard','aluminum','tire']: shutil.copytree(d/f'{m}-regression',e/f'{m}-regression',dirs_exist_ok=True)
sources={str(x.relative_to(r)):hashlib.sha256(x.read_bytes()).hexdigest() for folder in ['scripts','scenes','assets'] for x in (r/folder).rglob('*') if x.is_file()}
(b/'source-sha256.json').write_text(json.dumps(sources,indent=2),encoding='utf-8')
manifest={str(x.relative_to(b)):hashlib.sha256(x.read_bytes()).hexdigest() for x in b.rglob('*') if x.is_file() and x.name!='artifact-sha256.json'}
(b/'artifact-sha256.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
z=r/'builds/CrushFactory-M5-review-01-Windows-x64.zip'
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as out:
 for x in b.rglob('*'):
  if x.is_file(): out.write(x,x.relative_to(b))
with zipfile.ZipFile(z) as out: assert out.testzip() is None
print(json.dumps({'zip':str(z),'exe_sha256':sha,'performance':p,'cycles':len(v['cycles']),'visual_matches':len(images)},indent=2))



