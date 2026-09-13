# Crush Factory — M2 Aluminum Review 01

M1 已通过用户视觉验收，稳定提交 b9ac7ee。M2 待视觉验收，未进入 M3。

双击 CrushFactory.exe，默认使用铝罐，1280×720 Compatibility，无需 Godot、网络或账号。

| 操作 | 控制 |
|---|---|
| 开始 / 暂停 / 继续 | Space 或 PRESS / PAUSE |
| 回程 | R 或 RETURN |
| 新铝罐（压板回顶后） | N 或 NEW CAN |
| 正面 / 侧面 | 1 / 2 |
| 环绕 | 鼠标右键拖动、A / D |
| 拉近 / 拉远 | 滚轮、W / S |
| 静音 | M |
| 降低 / 提高压力 | - / = |
| 退出 | Esc |

在 100 压力下体验完整过程：局部凹陷 → 硬撑 → 三次局部屈曲与负载释放 → 紧凑金属层叠 → 回程后保持塑性变形。
金属屈曲声音每次关键失稳触发一次，不持续连发。没有轮胎、经济系统、复杂 UI 或新场景。

Evidence 目录包含正面/侧面全程视频、压缩前/首次凹陷/主屈曲/压实/回程后截图、性能 JSON、测试日志、已知问题。

纸箱原 Build 保留于 builds/M1-review-02；本版本可用 `CrushFactory.exe -- --cardboard` 运行相同纸箱基线，用于回归检查。

开发：Godot 4.7.2 standard，GDScript，Jolt，60Hz 固定物理步。构建运行 `powershell -File tools/build_m2.ps1`。
自动展示：`CrushFactory.exe -- --demo`，侧面加 `--side`；十轮实测：`CrushFactory.exe -- --benchmark`。日志默认写入 Godot 用户数据 records，也可设 CRUSH_RECORD_DIR。

已知边界：程序化壳体而非完整金属自碰撞；固定局部屈曲模式；拉环为贴图细节；合成占位音。当前比例为观察压缩服务，不代表真实饮料罐尺寸和工业载荷。自然度由用户视觉验收。本机外硬件尚未测试。
