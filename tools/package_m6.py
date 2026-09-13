from pathlib import Path
from collections import Counter
import hashlib, json, shutil, zipfile

r = Path(__file__).resolve().parents[1]
d = r/'records/m6-review01'
b = r/'builds/M6-review-01'
def data(name): return json.loads((d/name).read_text(encoding='utf-8-sig'))
def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
v, s, t = [data(f'gameplay-{n}.json') for n in ('verify','session','resume')]
assert not v['failures'] and not s['failures'] and not t['failures']
counts = Counter(x['object'] for x in v['cycles'])
assert counts == {'bottle':3,'cardboard':5,'aluminum':6,'tire':5,'crate':3,'pc':3,'microwave':3}
assert s['pid'] != t['pid'] and s['money'] == t['money'] == 333
assert t['level'] == 4 and len(t['unlocked']) == 7 and t['phase']=='SELECT'
assert all(x['scene_identical'] for x in data('visual-regression.json').values())
assert all(data('protected-sources.json')['unchanged'].values())
assert not data('input-dispatch.json')['failures']
tests = ['solver','cardboard','controller','review02','aluminum','aluminum_controller','rubber','tire','progress','gameplay','cadence','slice','content','content_progress','content_visual','content_controller']
for test in tests:
    text = (d/f'{test}_test.log').read_text(encoding='utf-8-sig')
    assert 'ERROR:' not in text and 'WARNING:' not in text, test
    assert 'PASS' in text or '0 failures' in text, test
for name in ['gameplay-session.log','gameplay-restart.log','gameplay-verify.log','input-dispatch.log']:
    text = (d/name).read_text(encoding='utf-8-sig')
    assert 'ERROR:' not in text and 'WARNING:' not in text, name
p = v['performance']
assert p['average_fps']>=30 and p['adapter'] and p['resolution']=='1280x720'
seconds = float(data('video-info.json')['format']['duration'])
report = f'''# M6 Content Expansion Prototype / Review 01

状态：开发交付完成，等待用户视觉验收。M5 稳定验收提交 `834dc10`；M5 原 Build、ZIP、Gameplay 与视觉证据保留，EXE 哈希已复核一致。本轮未创建 M6 稳定验收提交。

## 内容与结构行为

总计七种物品，没有加入车门。保留 M5 的纸箱、铝罐、轮胎、场景、灯光与主要 HUD。

|新增物品|独特结构行为|推荐压力 / 解锁|
|---|---|---|
|Plastic Bottle|PET 截面局部瘪陷、斜向折痕、瓶肩颈部偏移；卸载少量回弹，永久凹陷保留|80 / Level 1|
|Wooden Crate|连接失效后分段木板旋转、错开堆叠，角柱折断；无自由刚体碎片|140 / Level 3|
|PC Tower|薄壳先向内弯折，独立驱动器和内部机架随后错层、倾斜堆叠；开放检修侧便于观察|140 / Level 3|
|Microwave Oven|较宽设备外壳屈曲，独立门板绕下缘向腔体倾倒，控制侧与机壳继续堆叠|180 / Level 4|

复用 MaterialProfile / 有界 CrushSolver 位移、压板控制、公共结构事件、AudioStream Profile、奖励及原子存档。四种新物品有各自负载曲线和几何策略；共享几何辅助只负责网格输出和低频简化碰撞。
压力 80 / 100 / 140 / 180，升级费用 40 / 150 / 220。Level 1 保留已开放铝罐，并增加瓶子；Level 2 轮胎；Level 3 木箱/机箱；Level 4 微波炉。所有物品免费。

## 完整 Gameplay 与持久化

视频 {seconds:.2f} 秒。实际 Windows EXE：瓶子 → 纸箱 → Lv1 铝罐 → 升级 2 → 轮胎压缩及完整回弹 → Lv2 铝罐 → 升级 3 → 木箱 → PC → 升级 4 → 微波炉 → 领取 → 退出 → 新进程重启。

使用真实界面操作信号驱动，Movie Maker 30 FPS 录制引擎画面/音轨；没有伪造奖励或加钱。完整新游戏路径从 0 到 333 金币，三次升级均靠实际回收收入。进程 {s['pid']} → {t['pid']}，重启后 333 金币 / Level 4 / 七物品正确保留。视频在真实退出与重启处拼接。

铝罐 Lv1 峰值 {v['cycles'][2]['peak']*100:.2f}% → Lv2 {v['cycles'][4]['peak']*100:.2f}%。木箱 / PC 在 Lv3 可完整处理，Lv4 进一步缩短高负载阶段；微波炉临界负载高于 Lv3 最大压力。弱压力求解测试确认新增硬物体不能达到强压力的最终压缩率。
瓶子峰值 82%，卸载后约 75.8%，只回弹约 6.2 个百分点；轮胎约 65.9% → 21.3%，与瓶子的塑性行为明显不同。

## 验证结果

- 16 组代码/集成测试，以及一组引擎鼠标/键盘与滚动目录测试通过。覆盖接触前不变形、有界位移、暂停继续、提前回程、事件次数、重置、物体范围、弱压力停滞、M5 存档读取、四级扣款/解锁、保存失败回滚、奖励单领。
- 最终 Windows EXE 完成 {len(v['cycles'])} 个完整循环：纸箱 5、铝罐 6、轮胎 5，四种新增物品各 3。失败 0；每次核查机器包络、回程、奖励不可重复领取及磁盘读回。
- 12 个原材料/压板/音效/环境关键源文件与 M5 稳定提交一致。标准 Godot 使用旧验收场景复现 32 张正/侧截图，32 张全图均逐像素一致。旧场景截图来自标准版，完整游戏、录屏、性能来自最终 EXE。
- 七物品目录可滚动，鼠标可以选择底部微波炉；Space / F3 / R / C 与重复领取检查通过，1024×576 布局保留。输入为 Godot Input.parse_input_event，不宣称已验证 OS SendInput。
- 最终运行、导出与测试日志无 ERROR/WARNING。早期 headless 固定帧率加速检查退出出现两项 ObjectDB 清理提示，不作为发布版性能或运行结论；最终原生窗口版本独立复核。

## Intel UHD 性能

1280×720 / Compatibility / {p['adapter']}。最终 EXE，无录屏、无固定帧率、无并行 GPU 或编码负载，预热 2 秒后采集 {p['frames']} 帧。
平均 **{p['average_fps']:.2f} FPS**，P95 **{p['p95_ms']:.2f} ms**，P99 **{p['p99_ms']:.2f} ms**，最长 **{p['max_ms']:.2f} ms**。达到 30 FPS 最低目标；不声称锁定 60 FPS 或所有瞬时帧达标。录屏帧率不用于该结论。

## 已知问题与范围

- 新增网格仍是无品牌程序化原型，瓶子标签、木材裂口、设备内部、门窗与折皱细节尚未达到最终商业美术质量。
- 木板和设备部件使用受约束几何堆叠，紧凑阶段允许内部遮挡/交叠；不提供真实 fracture 或内部碰撞仿真。
- 暂无车门等超大物品；微波炉是本轮较宽设备终点。当前仍一台液压机，无自动工厂或新地图。
- 英文 HUD，未签名 Windows EXE；无云存档/手动改档防护。已升到 Level 3/4 的 M6 存档不要交给旧 M5 程序写入。中途退出放弃未领取物品。
- 此轮未继续打磨已验收纸箱、铝罐、轮胎的 Polish Backlog。

版本 0.6.0-m6-review.1。EXE SHA256：`{digest(b/'CrushFactory.exe')}`。
M6 在此暂停，不添加第八种物品，等待用户视觉验收。
'''
(d/'M6_REVIEW.md').write_text(report,encoding='utf-8')
for name in ['DEVELOPMENT_PLAN.md','DESIGN.md','README_M6.md','ASSET_LICENSES.md']:
    shutil.copy2(r/name,b/('README.md' if name=='README_M6.md' else name))
shutil.copy2(d/'M6_REVIEW.md',b/'M6_REVIEW.md')
shutil.copytree(r/'licenses',b/'licenses',dirs_exist_ok=True)
e = b/'evidence'; e.mkdir(exist_ok=True)
for name in ['gameplay-full.mp4','gameplay-session.json','gameplay-resume.json','gameplay-verify.json','visual-regression.json','protected-sources.json','video-info.json','audio-validation.log','gameplay-session.log','gameplay-restart.log','gameplay-verify.log','input-dispatch.log','input-dispatch.json']:
    shutil.copy2(d/name,e/name)
for path in list(d.glob('*.png'))+list(d.glob('*_test.log')):
    shutil.copy2(path,e/path.name)
for m in ['cardboard','aluminum','tire']:
    shutil.copytree(d/f'{m}-regression',e/f'{m}-regression',dirs_exist_ok=True)
sources = {str(x.relative_to(r)):digest(x) for folder in ['scripts','scenes','assets'] for x in (r/folder).rglob('*') if x.is_file()}
(b/'source-sha256.json').write_text(json.dumps(sources,indent=2),encoding='utf-8')
manifest = {str(x.relative_to(b)):digest(x) for x in b.rglob('*') if x.is_file() and x.name!='artifact-sha256.json'}
(b/'artifact-sha256.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
z = r/'builds/CrushFactory-M6-review-01-Windows-x64.zip'
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as out:
    for x in b.rglob('*'):
        if x.is_file(): out.write(x,x.relative_to(b))
with zipfile.ZipFile(z) as archive: assert archive.testzip() is None
print(json.dumps({'exe_sha256':digest(b/'CrushFactory.exe'),'files':len(manifest),'zip_bytes':z.stat().st_size,'performance':p},indent=2))
