# M1 纸箱正式视觉验收

用户明确确认：M1 视觉验收通过，已检查正面和侧面完整压缩视频；当前纸箱达到 M1 MVP 验收标准。

通过项目：接触后形变、非对称侧壁失稳、局部折叠、突然塌陷、多阶段压缩、回程后永久形变。

稳定版本：0.1.0-m1-review.2。
Windows EXE：builds/M1-review-02/CrushFactory.exe。
SHA256：9444d6bcedfca3580932f9ba095f1b8c922aff3282c21918e0e0c2cddaf4702e。
交付包：builds/CrushFactory-M1-review-02-Windows-x64.zip。
视觉和测试证据：records/review02；包内 Evidence 保存相同记录。

四组测试和最终 EXE 10 周期通过，Intel UHD 720p 平均 58.62 FPS，P95 19.91ms。原始报告保留当时“待验收”状态，本记录补充用户最终决定。

后续非阻塞 Polish：失稳前中间折痕、终态少量翘边/错层/厚度变化、更细压痕/磨损/撕裂。当前不实施。

本次独立验收提交使用 `M1: cardboard crush visual acceptance`。用户授权进入仅铝罐的 M2，不允许进入 M3。纸箱实现保持不变；公共修改需验证无纸箱视觉回归。
