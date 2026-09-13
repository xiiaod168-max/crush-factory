# Assets and dependencies

| 内容 | 来源 / 使用方式 |
|---|---|
| Godot 4.7.2 standard + Jolt | Godot 官方版本；MIT 与所带第三方许可，见 licenses/GODOT-LICENSE.txt 和 GODOT-COPYRIGHT.txt。游戏分发保留这些声明。 |
| 场景、机器、纸箱网格 | 本项目程序化生成，无第三方模型。 |
| 铝罐壳体、卷边和罐盖 | scripts/aluminum_can.gd 原创程序化网格；tools/make_can.py 原创涂装/拉环贴图，Arial 仅本机栅格化，不分发字体。 |
| 纸面、胶带、印刷纹理 | tools/make_paper.py 原创生成，固定随机种子；Windows Arial 仅用于本机栅格化文字，未分发字体文件。 |
| 机械循环与纸板冲击音 | scripts/press_audio.gd 原创程序化合成，无第三方采样。 |
| 铝罐屈曲音 | scripts/press_audio.gd 独立金属瞬态参数，原创合成，无第三方采样。 |
| 轮胎、胎纹和侧壁 | scripts/tire.gd 原创环形网格、局部形变与程序化橡胶 Shader，无第三方模型或贴图。 |
| 橡胶反馈音 | scripts/press_audio.gd 独立柔和摩擦/吱响瞬态参数，原创合成，无金属采样。 |
| Python / Pillow | 仅开发时生成纹理，不随游戏分发。 |
| FFmpeg 9.0.1 Gyan essentials | 仅本机验收录屏转码工具（GPLv3 build），不链接、不打包进游戏。保留在 tools/ffmpeg，许可随工具下载。 |

官方来源：https://godotengine.org/license/ ，https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable ，https://www.gyan.dev/ffmpeg/builds/

M5 新增 workshop-concrete.png、workshop-wall.png、workshop-paint.png、workshop-oil.png 均由 tools/generate_workshop.py 原创程序化生成。车间几何、轮胎解锁轮廓与 collect/upgrade/unlock 音效均为本项目原创代码生成，无第三方资产、无购买、无外部下载。沿用本项目原创资源许可，允许用于本游戏商业版本。
## M6 原创内容

塑料瓶、木箱、PC 机箱、微波炉的程序化网格，以及 PET / 木板 / 机壳 / 门铰链事件声音均为本项目原创代码生成，无新增第三方资源、采购或外部账号依赖。PC 内部仅为无品牌的简化机架与部件。沿用 M5 原创环境纹理及既有 Godot 许可。
