"""Assemble immutable M2 review evidence after final build checks."""
from pathlib import Path
import hashlib,json,shutil,zipfile

root=Path(__file__).resolve().parents[1]
records=root/'records/m2-review01'
build=root/'builds/M2-review-01'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
exe_hash=sha(build/'CrushFactory.exe')
assert exe_hash=='039bf36ab5b5a7f5e0cc0fe3d51c85901b482b6599710063d85b6bd12f3b8ac0'
benchmark=json.loads((records/'benchmark-gl_compatibility.json').read_text())
assert benchmark['version']=='0.2.0-m2-review.1'
assert benchmark['cycles']==10 and benchmark['buckle_events']==30 and not benchmark['failures']
regression=json.loads((records/'cardboard-regression.json').read_text())
assert all(regression['protected_sources_identical'].values())
assert all(row['identical'] for row in regression['screenshots'].values())
tests=['solver_test','cardboard_test','controller_test','review02_test','aluminum_test','aluminum_controller_test']
for name in tests:
    log=(records/f'{name}.log.console').read_text(encoding='utf-8-sig')
    assert 'ERROR:' not in log and 'WARNING:' not in log
    assert 'PASS' in log or 'Review02 tests: 0 failures' in log
for name in ['record-front','record-side','build-benchmark']:
    log=(records/f'{name}.log').read_text(encoding='utf-8')
    assert 'ERROR:' not in log and 'WARNING:' not in log
for view in ['front','side']:
    data=json.loads((records/f'{view}-video.json').read_text(encoding='utf-8-sig'))
    assert float(data['format']['duration'])>22
    assert [s['codec_name'] for s in data['streams']]==['h264','aac']
memory=json.loads((records/'process-memory.json').read_text(encoding='utf-8-sig'))
private=[m['private_bytes']/1048576 for m in memory]
report=f'''# M2 Aluminum Review 01 — 待用户视觉验收

版本：0.2.0-m2-review.1。M1 验收提交：b9ac7ee `M1: cardboard crush visual acceptance`。
M2 只实现铝罐；当前停止后续开发，等待用户视觉验收。未进入 M3，未创建 M2 验收 commit。

## 运行和证据
双击交付包根目录的 CrushFactory.exe，默认铝罐。Space 开始/暂停，R 回程，N 新罐，1/2 正侧面，右键环绕，滚轮缩放，M 静音。完整操作见 README.md。

- [正面完整过程](front-full.mp4) / [侧面完整过程](side-full.mp4)
- 正面：[压缩前](front-before.png) / [第一次凹陷](front-dent.png) / [主要屈曲](front-buckling.png) / [第二次折叠](front-folding.png) / [压实停板](front-compacted.png) / [回程后永久形变](front-after.png)
- 侧面：[压缩前](side-before.png) / [第一次凹陷](side-dent.png) / [主要屈曲](side-buckling.png) / [第二次折叠](side-folding.png) / [压实停板](side-compacted.png) / [回程后永久形变](side-after.png)

每段 22.30 秒，1280×720、30 FPS、669 帧、H.264/AAC，包含真实游戏控制驱动的完整下降、接触、三次失稳、停止、回程。采用最终 EXE 的原生逐帧录制；不是另外制作的演示动画，录制耗时不代表实时性能。完整视频均解码成功并保留音轨，音量检查附日志。压实瞬间罐体被压板遮住，回程后截图用于观察最终形状。

## 材料差异
- 铝罐是 64 段圆周、40 段高度的连续圆柱壳，局部凹陷、偏心、环形斜折和三组高度不同的塑性皱褶；没有复用纸箱折板网格。
- 初始阻力从 55 上升到约 84，高于纸箱；压缩约 12%、40%、67% 时触发三次局部屈曲，载荷分别降至约 16、20、22，随后重新承压。
- 关键失稳各触发一次约 67ms 停顿、0.30 秒短暂速度释放、短促金属声和轻微震动。不每帧播放事件，不触发纸屑。
- 金属卷边与罐盖跟随偏心形变，涂装 UV 随壳体变形；回程保留塑性应变。简化圆柱 Collider 低频同步，压板仍按 Solver 当前包络受限运动。

## 性能与稳定性
最终 Windows EXE、本机 Intel UHD Graphics、Compatibility、1280×720、默认垂直同步；预热 2 秒后按单调时钟采样实际帧间隔。没有同时录屏、转码或运行第二个渲染器。

| 完整周期 | 屈曲事件 | 平均 FPS | P95 | P99 | 最长帧 |
|---:|---:|---:|---:|---:|---:|
| {benchmark['cycles']} | {benchmark['buckle_events']} | {benchmark['average_fps']:.2f} | {benchmark['p95_ms']:.2f}ms | {benchmark['p99_ms']:.2f}ms | {benchmark['max_ms']:.2f}ms |

10 周期未记录压板越过包络、永久形变丢失或事件次数错误。每周期约 35 次简化 Collider 同步。本轮不生成金属碎片，因此没有碎片回收压力负载。
Release MEMORY_STATIC 不可用，JSON 中的 0 不是零占用。同一次运行采样 {len(memory)} 次进程 private bytes：首次 {private[0]:.2f}MiB、最后 {private[-1]:.2f}MiB，范围 {min(private):.2f}–{max(private):.2f}MiB；短程趋势不能证明长期无泄漏。
当前结果仅代表本机，未宣称独显 1080p 或其他渲染器的 M2 性能。

## 自动检查与纸箱回归
- 六组测试通过，最终完整控制台记录无 ERROR/WARNING。
- 铝罐测试覆盖局部凹陷、非对称圆环、接缝连续、各阶段包络和层间厚度、相邻应变连续、初始硬度、三次负载释放与永久性。
- 铝罐控制测试覆盖未接触不形变、暂停、提前回程后续压、位移上限、完整压缩、回程保留、重置后仍使用铝罐求解器、重复周期。
- 纸箱四组原测试通过。纸箱网格、求解公式、MaterialProfile 和两张贴图与 M1 文件校验一致。
- 从最终 M2 EXE 的 `--cardboard` 模式录制双视角：压缩前、屈曲、二次折叠、回程后共 8 张截图，与 M1 验收图逐像素一致。详见 cardboard-regression.json。回归截图保留于 cardboard-regression 子目录。
- 公共压板修改只有求解器工厂接入与重置选择，运动、查询、纸箱参数保持不变；入口、音效与录制增加了材质条件分支。

## 已知问题与边界
- 仍是可控程序化壳体，屈曲位置固定，部分环形皱褶可能有规则感；不是完整金属自碰撞和断裂模拟，满意度由用户确认。
- 拉环为罐盖贴图细节，不是独立可拉动机构；声音为合成占位音。未制作喷液、金属碎片或纤维级材质细节。
- 罐体比例为当前液压机的观看效果服务，不代表真实 330ml 尺寸或工业压力。
- 仅本机 Windows 验证，EXE 未商业代码签名。未制作轮胎、经营系统、复杂 UI 或扩展场景。

## 开发中发现并修正
1. 最初压缩分配把部分环挤到同一高度，造成末端细碎闪烁；改成保留正厚度的分段轴向分配，并增加层间厚度测试。
2. 修正圆周贴图方向和接缝，提亮涂装并拉近铝罐机位，纸箱机位不变。
3. 测试曾使用过短的帧数强制退出参数，截断清理造成退出警告；最终测试自行正常退出，控制台完整检查通过。
4. 独立 EXE 的相对录制路径不可写；已改成绝对路径重录，最终视频/日志均来自下述同一 EXE。

## 文件一致性与验收门槛
EXE SHA256：`{exe_hash}`。
artifacts-sha256.json 校验交付文件，source-sha256.json 记录本轮源码和资源。M1 Build、ZIP 和历史视觉证据保留不覆盖。
用户确认 M2 视觉通过前不创建 M2 验收提交，不进入 M3。
'''
(records/'M2_REVIEW.md').write_text(report,encoding='utf-8')
evidence=build/'Evidence'
evidence.mkdir(exist_ok=True)
names=['M2_REVIEW.md','front-full.mp4','side-full.mp4','benchmark-gl_compatibility.json','process-memory.json','cardboard-regression.json']
names += [f'{v}-{s}.png' for v in ['front','side'] for s in ['before','dent','buckling','folding','compacted','after']]
names += [f'{t}.log.console' for t in tests]
names += [f'{n}.log' for n in ['record-front','record-side','build-benchmark','front-audio-validation','side-audio-validation']]
names += ['front-video.json','side-video.json']
names += [f'cardboard-regression/{v}-{s}.png' for v in ['front','side'] for s in ['before','buckling','folding','after']]
for name in names:
    (evidence/name).parent.mkdir(exist_ok=True)
    shutil.copy2(records/name,evidence/name)
shutil.copy2(root/'README_M2.md',build/'README.md')
for name in ['ASSET_LICENSES.md','DEVELOPMENT_PLAN.md']:
    shutil.copy2(root/name,build/name)
sources=list((root/'scripts').glob('*.gd'))+list((root/'scenes').glob('*.tscn'))+list((root/'assets').glob('*.png'))+[root/'project.godot',root/'export_presets.cfg']
(build/'source-sha256.json').write_text(json.dumps({p.relative_to(root).as_posix():sha(p) for p in sources},indent=2),encoding='utf-8')
manifest={p.relative_to(build).as_posix():sha(p) for p in build.rglob('*') if p.is_file() and p.name!='artifacts-sha256.json'}
(build/'artifacts-sha256.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
archive=root/'builds/CrushFactory-M2-review-01-Windows-x64.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=3) as z:
    for p in build.rglob('*'):
        if p.is_file(): z.write(p,Path('CrushFactory-M2-review-01')/p.relative_to(build))
with zipfile.ZipFile(archive) as z: assert z.testzip() is None
assert all(sha(build/p)==value for p,value in manifest.items())
print(json.dumps({'exe_sha256':exe_hash,'zip_bytes':archive.stat().st_size,'cycles':benchmark['cycles'],'fps':benchmark['average_fps'],'m1_screenshots_identical':8},indent=2))
