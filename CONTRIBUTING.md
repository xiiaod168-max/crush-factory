# Contributing to Crush Factory

感谢你对 Crush Factory 的兴趣。这个仓库仍处于原型阶段，欢迎提交 bug、性能数据、硬件兼容性报告和小型改进。

## Before opening an issue

- 请先确认问题能在 Godot 4.7.2 standard、Windows x64 和 Compatibility renderer 下复现。
- 描述物品、Pressure Level、操作步骤、是否出现穿透/抖动/弹飞，以及完整的控制台错误。
- 如果是性能问题，请提供分辨率、显卡型号、renderer、平均 FPS、P95/P99 帧时间。
- 截图或短录屏很有帮助；不要上传存档、Token、密码或其他个人数据。

## Local setup

1. 安装 Godot 4.7.2 standard 和对应 Windows x64 export templates。
2. 打开 `project.godot`，运行 gameplay scene。
3. 运行相关测试：

   ```powershell
   tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/content_test.gd
   ```

4. 修改后运行与你改动相关的测试，并检查 `git diff --check`。

不要把 Godot binary、export templates、FFmpeg、`records/*` 录屏、`builds/*` 导出物或本地 `progress.json` 提交到源码分支。Windows Build 应作为 GitHub Release asset 提供。

## Design boundaries

- 保持 PressController 的确定性和 60 Hz 受约束位移。
- 新材料可以拥有专用 deformation strategy；不要只复制已有网格并更换颜色。
- Visual Mesh 与简化 Collider 分离，禁止每个 physics frame 重建复杂 Collider。
- 稳定性、手感和可读性优先于不必要的物理真实性。
- 修改公共 Crush 系统时，必须重新跑纸箱、铝罐和轮胎回归测试。

## Pull requests

请让一个 PR 只解决一个清晰问题，说明行为变化、验证命令、已知限制和截图/视频位置。不要在没有用户验收的情况下把 M6 标为 stable，也不要顺手加入第四阶段之外的新经营系统或大型场景。

代码和原创资源按 [MIT License](LICENSE) 提交。第三方资源必须在 `ASSET_LICENSES.md` 中记录来源和许可证。
