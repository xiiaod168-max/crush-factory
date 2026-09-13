# Windows 输入验证记录

尝试使用 computer-use 的 Windows 窗口观察/输入工具时，应用授权等待超时：Computer Use app approval timed out。未进行 OS SendInput 鼠标/键盘动作，不将其标记为通过，也未绕过授权。

替代的项目内测试 tests/hud_input_test.gd 通过 Godot Input.parse_input_event 分发鼠标按下/抬起和键盘事件，验证原生 Button 实际命中、空格暂停、F3 切换、R 回程、C 领取及重复领取保护。1024×576 实际渲染见 input-small.png / input-debug-small.png。此测试覆盖引擎的 GUI 事件路由，但不等于操作系统级自动输入测试。

测试发现空格按下后暂停、抬起又触发焦点按钮继续的问题。修复为快捷键的按下与抬起均由游戏统一消费，Enter 保留原生按钮激活。修复后按下/抬起均保持 PAUSED，整个测试通过，最终 EXE 已重新导出。
