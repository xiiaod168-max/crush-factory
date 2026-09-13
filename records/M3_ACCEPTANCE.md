# M3 轮胎正式视觉验收

用户明确确认 M3 视觉通过，已观看正面、侧面完整视频。
通过：接触后弹性抵抗、横向鼓出、中心孔椭圆化、大幅弹性形变、卸载后渐进回弹、可见残留损伤、无明显弹飞/严重抖动/穿透。三种材料行为已明显区分。

稳定版本 0.3.0-m3-review.1。
EXE SHA256：9bba165cf81f565d9f981c81f7ac185b2d706e0fa76ec56ffc7fd1e34cefae19。
原 Build：builds/M3-review-01/CrushFactory.exe；原视频/截图：records/m3-review01。
原 review ZIP 保留不覆盖；带本验收记录的包：builds/CrushFactory-M3-accepted-Windows-x64.zip。

验收时重新执行纸箱四组、铝罐两组逻辑测试，均通过；records/m3-acceptance 保留日志。重新校验 20 张双视角阶段截图与 M1/M2 验收基线一致，九个受保护源码/资源文件一致。
原轮胎十周期结果：平均 60.28 FPS，P95 18.36ms；每轮回弹约 5.4 秒，保留约 21% 损伤。

Polish 非阻塞：非线性多段回弹、更明显 residual damage、永久鼓出/孔偏心/侧壁损伤、商业胎纹与材质细节。当前不改轮胎。
提交：M3: tire elastic deformation visual acceptance。
用户授权 M4 仅连接当前三种物品的核心循环，不增加第四种物品；M4 完成后等待 Gameplay 验收。
