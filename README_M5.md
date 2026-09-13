# Crush Factory — M5 Vertical Slice Review 01

双击 CrushFactory.exe 开始。Windows x64 / 1280×720 / Compatibility。

免费选物 → PRESS → RETURN → 等待卸载（轮胎回弹）→ COLLECT → 赚取 40 金币购买升级 → 查看 PRESS UPGRADED → 查看 NEW OBJECT UNLOCKED → TRY THE TIRE。

主按钮随游戏状态变化。F3 开关 Debug HUD，默认关闭。空格压缩/暂停，R 回程，C 领取，N 选物，U 升级，M 静音，右键旋转视角，滚轮缩放，Esc 退出。声音按钮与退出按钮在右下。

远离物品时快进，接近后减速，接触压缩保持已验收速度；回程加速。奖励保存成功后有金币计数、机械确认音；升级和轮胎解锁有独立页面和反馈。

存档沿用 M4：%APPDATA%\Godot\app_userdata\Crush Factory\progress.json。金币、压力等级、解锁与声音设置即时保存；中途场景不保存，退出放弃未领取奖励。旧档自动保留进度，已有 Lv2 的玩家不会再次出现首次升级。不要手动修改正在运行的存档。

奖励公式和价格沿用 M4：round(基础价值 × 材质难度 × (0.25 + 0.75 × 峰值压缩率)) + 完成奖励；零形变零奖励。轮胎按峰值计奖。

当前仅三种免费物品和两级压力，不含复杂经营、Steam API 或第四物品。材质形变保持 M4 基线。原创程序化环境、纹理、图标与音效，无购买素材。

已知限制：英文界面；未签名 EXE；无云存档或手动改档防护；损坏存档仅保护原文件并提示；场景为小型 Vertical Slice，未进行商业资产精修。M5 等待视觉验收，稳定 M4 提交 1c4165e。
