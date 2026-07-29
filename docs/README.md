# Adaptive Strategic AI 开发文档

本目录保存可追溯的产品与工程决策。研究基线日期为 2026-07-29，游戏范围暂定为《文明 VI：风云变幻》单人对 AI 对局。

- `PRODUCT_GOALS.md`：玩家体验目标、公平边界、适用范围与验收标准。
- `GAME_MECHANICS.md`：与 AI 强弱有关的基础机制、原版文件证据和 Mod 能力边界。
- `AI_MOD_RESEARCH.md`：现有 AI/难度 Mod 的实现路线、优缺点和可借鉴结论。
- `ARCHITECTURE.md`：当前实现审计、目标架构与分阶段路线图。
- `TESTING.md`：固定种子测试矩阵、指标、日志要求和发布门槛。
- `DEVELOPMENT.log`：本机开发流水账，受 `*.log` 规则排除，不进入 Git。

阅读顺序建议：先确认 `PRODUCT_GOALS.md`，再根据 `ARCHITECTURE.md` 开发，最后按 `TESTING.md` 验收。任何参数修改都应能追溯到目标、机制证据或测试结果之一。
