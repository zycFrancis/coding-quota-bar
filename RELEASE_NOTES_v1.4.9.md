# Quota Bar v1.4.9

## 新增

- **自动化菜单入口**：外部可通过分布式通知触发状态栏菜单弹出，供 AppleScript 与自动化测试驱动：

```bash
python3 -c "import subprocess; subprocess.run(['osascript','-e','tell application \"System Events\" to notify') " # 示例见 README
```

或任意语言向 `local.quotabar.showMenu` 发送 DistributedNotification。

## 其他

- 依赖与行为无变化；配套发布验证脚本。
