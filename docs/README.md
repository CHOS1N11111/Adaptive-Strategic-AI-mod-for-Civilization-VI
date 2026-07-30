# Adaptive Strategic AI 开发文档

本目录保存可追溯的产品与工程决策。研究基线日期为 2026-07-29，游戏范围暂定为《文明 VI：风云变幻》单人对 AI 对局。

## 目录分类

```text
docs/
|-- product/    产品目标与公平边界
|-- research/   游戏机制、外部资料与现有 Mod 调研
|-- design/     架构、接口与实现路线
|-- quality/    测试、指标与发布标准
`-- process/    本地开发过程记录
```

### product

- [`PRODUCT_GOALS.md`](product/PRODUCT_GOALS.md)：玩家体验目标、公平边界、适用范围与验收标准。

### research

- [`GAME_MECHANICS.md`](research/GAME_MECHANICS.md)：与 AI 强弱有关的基础机制、原版文件证据和 Mod 能力边界。
- [`AI_MOD_RESEARCH.md`](research/AI_MOD_RESEARCH.md)：现有 AI/难度 Mod 的实现路线、优缺点和可借鉴结论。

### design

- [`ARCHITECTURE.md`](design/ARCHITECTURE.md)：当前实现审计、目标架构与分阶段路线图。
- [`PVP_EXPERIENCE.md`](design/PVP_EXPERIENCE.md)：PvP 式体验、竞争护栏、长期计划与后续实现合同。

### quality

- [`TESTING.md`](quality/TESTING.md)：固定种子测试矩阵、指标、日志要求和发布门槛。
- [`reports/`](quality/reports/README.md)：按对局保存的实测分析、问题证据和优化结论。

### process

- [`README.md`](process/README.md)：过程资料的保存规则。
- `DEVELOPMENT.log`：本机开发流水账，受 `*.log` 规则排除，不进入 Git。

阅读顺序建议：先确认产品目标，再阅读机制与竞品研究，然后根据架构开发，最后按测试标准验收。任何参数修改都应能追溯到目标、机制证据或测试结果之一。
