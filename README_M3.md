# Crush Factory — M3 Rubber Tire Review 01

M1 已验收：b9ac7ee；M2 已验收：7ae3509。M3 轮胎待视觉验收，不进入 M4。

双击 CrushFactory.exe，默认轮胎，Windows x64 / 1280×720 / Compatibility，无需安装 Godot、联网或账号。

Space：开始/暂停/继续；R：回程；N：回顶后换新轮胎；1/2：正/侧面；右键、A/D：环绕；滚轮、W/S：远近；M：静音；-/=：压力；Esc：退出。

默认 100 压力可观察高压损伤。压实后按 R，继续观看约 5–6 秒：机器松开，轮胎缓慢回弹，但留下可见扁平和局部偏心。
较早按 R 可检查无损伤回弹。轮胎暂停时保持承压状态；回程后仍可继续压同一轮胎，损伤不会因再次施压而清除，只有 N 更换新胎才会清除。

Evidence 包含双视角完整视频及未受压、中度压缩、最大压缩、开始回程、回弹中、残留损伤截图，以及性能和错误日志。

旧材料回归模式：`CrushFactory.exe -- --cardboard`、`CrushFactory.exe -- --aluminum`。原 M1/M2 Build 与证据仍保留在各自目录。
开发版本固定 Godot 4.7.2 standard / Jolt / GDScript，60Hz 固定物理步；轮胎使用程序化网格与受限弹性求解，没有 SoftBody 或自由刚体弹射。
构建：`powershell -File tools/build_m3.ps1`。自动展示：`CrushFactory.exe -- --demo`，侧面加 `--side`；十轮实时测试：`-- --benchmark`。

局限：固定程序化损伤位置，简化橡胶截面/胎纹，合成声音；没有精确橡胶材料仿真或内部气压模拟。当前测试只代表本机。未制作金币、升级、订单或新场景。
