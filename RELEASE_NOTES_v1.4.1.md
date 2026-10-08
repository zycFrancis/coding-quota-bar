# Quota Bar v1.4.1

个人分支版本：新增 **GLM Coding Plan** 额度监控（上游 `pumpkinpieuncle/quota-bar` 暂不支持）。

## 新增

- GLM Coding Plan 卡片：读取 `open.bigmodel.cn/api/monitor/usage/quota/limit`，展示 5 小时窗口、每周额度与 MCP 月度额度的剩余百分比及重置倒计时。
- GLM 凭证自动发现，零弹窗：
  1. 环境变量 `ZAI_CODING_CN_API_KEY` / `GLM_API_KEY` / `ZAI_API_KEY`；
  2. `~/.dsh/.credentials.yaml` 的 `refs.ZAI_CODING_CN_API_KEY`；
  3. `~/.zai/credentials.json`。
  不使用 macOS 钥匙串，不会触发授权弹窗。
- 应用内"检查更新"指向本 fork（`zycFrancis/quota-bar`），不会被上游发布提醒覆盖。

## 说明

- 其余功能与上游 v1.4.0 一致。
