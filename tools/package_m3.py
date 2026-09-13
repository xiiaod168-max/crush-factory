"""Package the verified tire build and complete rebound evidence."""
from pathlib import Path
import hashlib,json,shutil,zipfile
root=Path(__file__).resolve().parents[1]
records=root/'records/m3-review01'
build=root/'builds/M3-review-01'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
exe_hash=sha(build/'CrushFactory.exe')
assert exe_hash=='9bba165cf81f565d9f981c81f7ac185b2d706e0fa76ec56ffc7fd1e34cefae19'
result=json.loads((records/'benchmark-gl_compatibility.json').read_text())
assert result['version']=='0.3.0-m3-review.1' and result['cycles']==result['damage_events']==10 and not result['failures']
assert len(result['recoveries'])==10
for r in result['recoveries']:
    assert r['peak']>0.65 and 0.19<r['residual']<0.23 and r['elastic']<0.0031 and r['rebound_seconds']>4
regression=json.loads((records/'plastic-regression.json').read_text())
assert all(regression['protected_sources'].values()) and all(x['identical'] for x in regression['screenshots'].values())
tests=['solver_test','cardboard_test','controller_test','review02_test','aluminum_test','aluminum_controller_test','rubber_test','tire_test']
for name in tests:
    text=(records/f'{name}.log.console').read_text(encoding='utf-8-sig')
    assert 'ERROR:' not in text and 'WARNING:' not in text
    assert 'PASS' in text or 'Review02 tests: 0 failures' in text
for name in ['record-front','record-side','build-benchmark']:
    text=(records/f'{name}.log').read_text(encoding='utf-8')
    assert 'ERROR:' not in text and 'WARNING:' not in text
for view in ['front','side']:
    data=json.loads((records/f'{view}-video.json').read_text(encoding='utf-8-sig'))
    assert float(data['format']['duration'])>19.7
    assert [s['codec_name'] for s in data['streams']]==['h264','aac']
memory=json.loads((records/'process-memory.json').read_text(encoding='utf-8-sig'))
private=[m['private_bytes']/1048576 for m in memory]
rows='\n'.join(f"| {i+1} | {r['peak']*100:.2f}% | {r['residual']*100:.2f}% | {r['damage']*100:.2f}% | {r['rebound_seconds']:.2f}s |" for i,r in enumerate(result['recoveries']))
report=f'''# M3 Rubber Tire Review 01 — 等待用户视觉验收

版本 0.3.0-m3-review.1。M1 稳定提交 b9ac7ee，M2 稳定提交 7ae3509。
M3 仅开发轮胎；当前暂停后续开发，不进入 M4，不提前创建 M3 验收 commit。

## 运行与视觉证据
双击交付目录的 CrushFactory.exe。Space 压下/暂停，R 回程，N 回顶后换胎，1/2 正侧面，右键环绕，滚轮缩放，M 静音，Esc 退出。完整说明见 README.md。

- [正面完整视频](front-full.mp4) / [侧面完整视频](side-full.mp4)
- 正面：[未受压](front-before.png) / [中度压缩](front-moderate.png) / [最大压缩](front-maximum.png) / [开始回程](front-return-start.png) / [回弹过程](front-rebounding.png) / [回弹后残留损伤](front-after.png)
- 侧面：[未受压](side-before.png) / [中度压缩](side-moderate.png) / [最大压缩](side-maximum.png) / [开始回程](side-return-start.png) / [回弹过程](side-rebounding.png) / [回弹后残留损伤](side-after.png)

两段均为最终 EXE 原生逐帧录制的真实控制流程，各 19.77 秒，1280×720、30 FPS、593 帧、H.264/AAC，完整包含接触、压缩、停板、回程、约 5.4 秒缓慢回弹和结束后的观察。两段视频完整解码，带声音。离线录制耗时不作为性能数字。

## 橡胶实现与材料区别
- 轮胎竖放，中心孔朝正面。独立环形网格同时改变高度、横向宽度、侧壁厚度、孔形、局部胎面和前后偏心；受压孔从圆形变为扁椭圆。
- elastic_deformation 和 permanent_damage 分开储存。低中等压力主要积累弹性应变；高压 78 以上且压缩超过约 48% 才开始积累永久损伤。
- 阻力随压缩平滑非线性增加：初始 18，最大约 85；没有铝罐的三次负载突然释放。
- 最大压缩约 66%；卸载单调渐进恢复，恢复速度上限约 0.261m/s，且高度不能超过压板当前间隙。恢复大部分形变，保留约 21% 高度损失和局部侧壁凹陷/偏心。
- 损伤阈值触发一次轻微相机反馈和柔和橡胶瞬态，未复制金属音。没有大量粒子或自由刚体。
- 简化 BoxShape 按 100ms/约 2% 高度差同步；回弹接近稳定时补一次同步。不是每帧重建复杂碰撞。

## 最终 EXE 实时性能
Intel UHD Graphics / Compatibility / 1280×720 / 默认垂直同步；2 秒预热，Time.get_ticks_usec 实际帧间隔。测试期间不录屏、不转码、不运行第二个渲染器。

| 完整压缩/回弹周期 | 损伤事件 | 平均 FPS | P95 | P99 | 最长帧 |
|---:|---:|---:|---:|---:|---:|
| {result['cycles']} | {result['damage_events']} | {result['average_fps']:.2f} | {result['p95_ms']:.2f}ms | {result['p99_ms']:.2f}ms | {result['max_ms']:.2f}ms |

未记录压板穿过弹性包络、无回弹、瞬间完美复原或损伤事件次数错误。下表应变相对于原始高度，回弹结束按剩余弹性应变低于 0.3% 判断；视频在此后继续观察 3 秒，十轮测试在此后等待 0.3 秒再换胎。

| 周期 | 最大形变 | 回弹后总残余 | 永久损伤 | 回弹时间 |
|---:|---:|---:|---:|---:|
{rows}

同一次运行采集 {len(memory)} 个进程内存样本，private bytes 首次 {private[0]:.2f}MiB、最后 {private[-1]:.2f}MiB，范围 {min(private):.2f}–{max(private):.2f}MiB。此短程趋势不能证明长期无泄漏。没有大量碎片负载，也没有其他硬件/1080p/其他渲染器的 M3 性能承诺。

## 自动测试与旧材料保护
- 八组自动测试通过，最终完整控制台记录无 ERROR/WARNING。
- Rubber：非线性阻力、接触前无变形、中压无损恢复、高压损伤、一次事件、单调限速回弹、再次压缩不能自愈、压板间隙约束。
- Tire：全阶段包络与有限坐标、孔形保持开放且明显椭圆化、横向鼓出、接缝连续、暂停保持、完整压缩/回程/回弹/损伤保留、换胎清除历史、提前回程恢复。
- 纸箱四组及铝罐两组原测试通过。相关材料网格、求解器、MaterialProfile 与贴图共 9 个文件与 M2 基线校验一致。
- 最终 M3 EXE 的纸箱双视角 8 张截图、铝罐双视角 12 张截图，共 20 张与各自已验收图逐像素一致。详见 plastic-regression.json 和回归截图目录。
- 公共控制器新增材料压缩上限与弹性恢复接入，塑性材料参数保持原值；旧材料测试只延长退出清理等待，没有改动验收断言。

## 已知问题与边界
- 轮胎采用简化环形截面与固定程序化损伤，胎面/侧壁细节仍较粗，可能带有圆环感；自然度、橡胶感由用户验收。
- 未模拟内部气压、帘布层、真实橡胶黏弹性或轮胎自碰撞。没有工业物理精度承诺。
- 轮胎固定在台面，无搬运、滚动或自由刚体飞起。音效是合成占位音，损伤位置不随机。
- 只在当前 Windows 设备验证，EXE 未商业代码签名。未制作金币、升级、订单、复杂 UI 或场景扩展。

## 修正记录
1. 原塑性流程不能满足回弹，新增独立橡胶求解器与单独展示流程，未沿用塑性永久压缩结果。
2. 调整回顶后 Collider 同步条件，避免恢复尾段因 READY 状态而频繁强制同步。
3. 快速手动步进测试的 0.15 秒退出等待偶发遗留音频资源；只在测试中延长至 0.5 秒，让音频清理完成。最终八组日志无警告。

## 一致性与验收门槛
EXE SHA256：`{exe_hash}`。
artifacts-sha256.json 校验交付文件，source-sha256.json 标识本轮源码与资源。M1/M2 原 Build 和视觉证据保留不覆盖。
M3 当前停在视觉验收门槛；用户明确通过之前不提交 M3 验收 commit，不进入 M4。
'''
(records/'M3_REVIEW.md').write_text(report,encoding='utf-8')
evidence=build/'Evidence'
evidence.mkdir(exist_ok=True)
names=['M3_REVIEW.md','front-full.mp4','side-full.mp4','benchmark-gl_compatibility.json','process-memory.json','plastic-regression.json','front-video.json','side-video.json']
names += [f'{v}-{s}.png' for v in ['front','side'] for s in ['before','moderate','maximum','return-start','rebounding','after']]
names += [f'{t}.log.console' for t in tests]
names += [f'{n}.log' for n in ['record-front','record-side','build-benchmark','front-audio-validation','side-audio-validation']]
for mode,stages in [('cardboard',['before','buckling','folding','after']),('aluminum',['before','dent','buckling','folding','compacted','after'])]:
    names += [f'{mode}-regression/{v}-{s}.png' for v in ['front','side'] for s in stages]
for name in names:
    (evidence/name).parent.mkdir(exist_ok=True)
    shutil.copy2(records/name,evidence/name)
shutil.copy2(root/'README_M3.md',build/'README.md')
for name in ['ASSET_LICENSES.md','DEVELOPMENT_PLAN.md']: shutil.copy2(root/name,build/name)
sources=list((root/'scripts').glob('*.gd'))+list((root/'scenes').glob('*.tscn'))+list((root/'assets').glob('*.png'))+[root/'project.godot',root/'export_presets.cfg']
(build/'source-sha256.json').write_text(json.dumps({p.relative_to(root).as_posix():sha(p) for p in sources},indent=2),encoding='utf-8')
manifest={p.relative_to(build).as_posix():sha(p) for p in build.rglob('*') if p.is_file() and p.name!='artifacts-sha256.json'}
(build/'artifacts-sha256.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
archive=root/'builds/CrushFactory-M3-review-01-Windows-x64.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=3) as z:
    for p in build.rglob('*'):
        if p.is_file(): z.write(p,Path('CrushFactory-M3-review-01')/p.relative_to(build))
with zipfile.ZipFile(archive) as z: assert z.testzip() is None
assert all(sha(build/p)==value for p,value in manifest.items())
print(json.dumps({'exe_sha256':exe_hash,'zip_bytes':archive.stat().st_size,'cycles':result['cycles'],'fps':result['average_fps'],'old_material_screenshots_identical':20},indent=2))
