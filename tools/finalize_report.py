"""Package existing, verified evidence. Does not build or change game behavior."""
import hashlib
import json
from pathlib import Path
import shutil
import zipfile

root = Path(__file__).resolve().parents[1]
records = root / 'records'
build = root / 'builds/M1-review-01'
reports = [json.loads((records / f'benchmark-{r}.json').read_text())
           for r in ('gl_compatibility', 'mobile', 'forward_plus')]
assert reports[0]['cycles'] == 10
assert all(not r['failures'] and 'Time.get_ticks_usec' in r['timing'] for r in reports)
tests = ['solver_test', 'cardboard_test', 'controller_test']
for name in tests:
    log = (records / f'{name}.log').read_text(encoding='utf-8')
    assert 'PASS' in log and 'ERROR:' not in log and 'WARNING:' not in log
exe_hash = hashlib.sha256((build / 'CrushFactory.exe').read_bytes()).hexdigest()
rows = '\n'.join(f"| {r['renderer']} | {r['cycles']} | {r['average_fps']:.1f} | {r['p95_ms']:.2f} | {r['p99_ms']:.2f} | {r['max_ms']:.2f} |" for r in reports)
text = f'''# M1 Review 01 — 待用户视觉验收

版本：0.1.0-m1-review.1。M0 稳定 commit：217cd6f。
M1 未创建验收 commit，未进入 M2。请先体验纸箱，满意后再确认。

## 直接运行与视觉证据
运行上一级目录的 CrushFactory.exe。Space 启停；R 回程；N 新纸箱；1/2 正侧面；右键环绕；滚轮缩放；M 静音。

- [正面完整过程（16.53 秒，含声音）](front-full.mp4)
- [侧面完整过程（16.53 秒，含声音）](side-full.mp4)
- 正面：[之前](front-before.png) / [折叠中](front-folding.png) / [回程后](front-after.png)
- 侧面：[之前](side-before.png) / [折叠中](side-folding.png) / [回程后](side-after.png)

视频为同一 EXE 的原生 Movie Maker 逐帧录制，1280×720、30 FPS，H.264/AAC；真实玩法控制驱动，不是另外制作的动画。离线录制耗时不能代表实际 FPS。侧面采用约 57° 视角，避免立柱遮住纸箱中心。

## 性能实测
本机 Intel UHD Graphics。最终 EXE 正常有窗口运行、1280×720、默认垂直同步、预热 2 秒；用 Time.get_ticks_usec 记录真实帧间隔。测试时没有同时录屏或运行其他渲染器。

| 渲染器 | 完整周期 | 平均 FPS | P95 ms | P99 ms | 最大 ms |
|---|---:|---:|---:|---:|---:|
{rows}

默认 Compatibility 达到本机 720p 的 30 FPS 最低目标，并接近 60 FPS 优选目标，但不是每一帧都严格低于 16.67ms。Mobile、Forward+ 仅各测一轮，证明可运行，不代表长期稳定或高级特效成本已验证。默认不切换渲染器。

Release 的 Godot MEMORY_STATIC 计数不可用（原始 JSON 中的 0 不是零占用）。此前开发版 10 周期静态内存约 74.45 → 74.63 MB，采样数组本身也增长。另附 release-process-memory-final.json 的进程占用抽样；不将单点占用当作泄漏证明。

## 测试结果
- Solver：无接触无形变、低压停滞、压缩上限、卸载永久性通过。
- Controller：暂停保持、异常高速位移限制、完整压缩、提前回程、部分损伤保留、续压、回顶与重置通过。
- Geometry：侧向折叠区别于整体缩放，四面共享边连续，顶底包络与有限坐标通过。
- 实际运行：10 个完整周期无压板越界或卸载损伤丢失；每周期约 36 次简化 Collider 同步。当前没有自由碎片，未声称通过大量碎片压力测试。
- 最终三组测试日志无 ERROR/WARNING。两个最终录制运行正常退出；视频完整解码，音轨峰值 -8.3 dB，无静音或削波。
- Git diff --check 通过。独立子代理审查因服务额度不可用未完成；本任务进行了本地代码复核。

## 已知问题与边界
- 折叠是低面数程序化几何，折痕仍有规则感；顶部较平整，没有纤维级撕裂。是否足够自然、有力量感由用户决定。
- 声音是合成占位音，不是实录。尚未制作灰尘/碎片或高端电影后处理。
- 物品已定位在台面；相机是受限环绕，不是自由行走或搬运。
- 压力值是游戏刻度，碰撞体是简化包络，不是工业精度。
- 仅测试当前电脑。Windows Build 未购买代码签名证书。
- 不含铝罐、轮胎、经济升级、存档、订单或复杂 UI。

## 开发中修正与选择
1. 修正纸箱三角形朝向造成的错误明暗；折线改成不对称且边界连续。
2. 调整侧面机位，避免立柱遮挡验收主体。
3. 修正音频关闭时序；测试和正常退出释放播放资源。
4. 性能采样从引擎平滑 delta 改为单调时钟；旧数值不作为最终结果。
5. 使用程序化折叠，不引入 SoftBody 或额外物理插件。没有反复失败后仍坚持同一路线。

## 文件一致性
最终 EXE SHA256：`{exe_hash}`。
同包的 artifacts-sha256.json 记录 Build、截图、视频校验；source-sha256.json 记录本次游戏源码和资源版本。M1 保持工作区修改状态，等待用户确认后提交。
'''
(records / 'M1_REVIEW.md').write_text(text, encoding='utf-8')
evidence = build / 'Evidence'
evidence.mkdir(exist_ok=True)
names = ['M1_REVIEW.md', 'front-full.mp4', 'side-full.mp4',
         'release-process-memory-final.json']
names += [f'{view}-{stage}.png' for view in ('front','side') for stage in ('before','folding','after')]
names += [f'benchmark-{r}.json' for r in ('gl_compatibility','mobile','forward_plus')]
names += [f'{test}.log' for test in tests]
for name in names:
    shutil.copy2(records / name, evidence / name)
manifest = {'CrushFactory.exe': exe_hash}
for name in names:
    manifest['Evidence/' + name] = hashlib.sha256((evidence / name).read_bytes()).hexdigest()
(build / 'artifacts-sha256.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
sources = list((root/'scripts').glob('*.gd')) + list((root/'scenes').glob('*.tscn')) + list((root/'assets').glob('*.png')) + [root/'project.godot',root/'export_presets.cfg']
source_hashes = {str(p.relative_to(root)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}
(build/'source-sha256.json').write_text(json.dumps(source_hashes,indent=2),encoding='utf-8')
with zipfile.ZipFile(root/'builds/CrushFactory-M1-review-01-Windows-x64.zip','w',zipfile.ZIP_DEFLATED,compresslevel=3) as z:
    for path in build.rglob('*'):
        if path.is_file(): z.write(path,Path('CrushFactory-M1')/path.relative_to(build))
print('Packaged Windows build, 2 full videos, 6 screenshots, reports, licenses and checksums.')
