# 生产与经济转化诊断

> 分类：系统设计 | 版本：0.6.0 | [返回文档索引](../README.md)

## 1. 目的与边界

城市和人口只说明帝国拥有资产，不能说明资产正在产生多少生产力，也不能说明生产力、金币和战略资源是否转化为区域、建筑、商路、改良或现代化单位。0.6.0 增加一层只读诊断，用于区分：

- 帝国规模不足。
- 城市产能不足。
- 有产能但区域、商路或改良没有跟上。
- 有金币或战略资源，但单位现代化积压。
- 城市生产分配与短板不一致。

本版本不把这些指标加入相对总分，不新增策略，不改变任何权重，也不把单次高金币或高库存直接判定为浪费。只有跨多个评估窗口持续出现“可用储备高、明确瓶颈存在、对应资产没有增长”，后续控制器才有资格考虑干预。

## 2. 日志合同

两条日志都包含 `turn`、`evaluated_turn`、`standard_turn` 和 `player`；转化行另含 `cities`，用于直接验证当前生产分类是否覆盖全部城市。

### 2.1 `ASAI_ECONOMY`

| 字段 | 定义 |
| --- | --- |
| `production` | 所有城市当前每回合生产力之和。 |
| `production_per_city` | 总生产力除以城市数。 |
| `production_per_pop` | 总生产力除以人口。 |
| `production_ratio` | AI 总生产力除以存活人类玩家平均总生产力。 |
| `production_per_city_ratio` | AI 每城生产力除以人类玩家平均每城生产力。 |
| `district_used` | 已建且占人口区域槽的区域数。 |
| `district_slots` | 当前人口允许的区域槽总数。 |
| `district_util` | `district_used / district_slots`；无槽位时为 `-1`。 |
| `district_open_cities` | 至少还有一个人口区域槽的城市数。 |
| `route_capacity` | 当前对外商路容量。 |
| `route_coverage` | `min(现有商人, 容量) / 容量`。这是容量覆盖代理，不是已建立路线数。 |
| `route_pipeline` | 将当前正在生产的商人计入后的容量覆盖代理。 |
| `improvement_coverage` | 已完成改良数除以现有基建目标。 |
| `improvement_pipeline` | 将现役及在产建造者按每个两个潜在改良计入后的覆盖率。 |
| `improved_land` | 已改良地块占拥有地块的比例。 |
| `production_ok` | 生产力 API 成功为 1，失败为 0。 |
| `district_ok` | 区域槽 API 成功为 1，失败为 0。 |

基建目标沿用控制器现有公式：`max(2 × 城市数, min(0.65 × 人口, 0.30 × 已拥有地块))`。覆盖率不截断到 1，以便识别明显过量。

### 2.2 `ASAI_CONVERSION`

| 字段 | 定义 |
| --- | --- |
| `queue_units/districts/buildings/projects` | 当前分别生产对应类别的城市数。单位包含军用和平民单位。 |
| `queue_idle` | 当前生产哈希为空的城市数。 |
| `queue_unknown` | 有生产哈希但无法映射到四类数据库对象的城市数。 |
| `gold_reserve` | 现有财政恢复使用的最低储备：每城 15 金币。 |
| `gold_surplus` | `max(0, 金币余额 - 最低储备)`，只表示可动用能力。 |
| `gold_per_city` | 金币余额除以城市数。 |
| `uncommitted_gold` | 从 `gold_surplus` 扣除全部已识别升级成本后的余额代理；不包含购买建筑、单位或伟人的潜在计划。 |
| `strategic_stockpile/capacity` | 当前已拥有或有净流量的战略资源库存及其库存上限合计。 |
| `strategic_fill` | 上述库存合计除以上限合计；没有相关资源时为 `-1`。 |
| `strategic_net` | 本地提取、城邦输入和奖励来源，扣除单位及发电消耗后的每回合净变化合计。 |
| `strategic_types` | 当前有库存或净流量的战略资源种类数。 |
| `strategic_full_types` | 库存达到各自上限 90% 的战略资源种类数。 |
| `upgradeable` | 引擎暴露升级命令且存在正金币成本的单位数。 |
| `upgrade_ready` | 当前条件下可立即执行升级命令的单位数。 |
| `upgrade_cost` | 所有已识别升级的金币成本合计。 |
| `queue_ok/resource_ok/upgrade_ok` | 对应传感器成功为 1，失败为 0。 |

`upgrade_ready` 会受到金币、资源、位置、行动状态和引擎排除条件影响，不能单独解释为 AI 是否“愿意”升级。战略资源合计也不能替代分资源需求；它首先用于发现长期满仓和现代化积压的相关性。

## 3. API 与降级

生产、队列、区域槽、战略资源和升级分别运行在独立的 `pcall` 中。任一组失败时：

1. 首次失败输出一条 `ASAI_DIAGNOSTIC_ERROR sensor=<name>`。
2. 该组字段填 `-1`，成功标记填 `0`。
3. 其他诊断组继续输出。
4. 原有 `ASAI_METRIC`、状态机和策略条件不受影响。

当前生产分类继续只使用已在玩法脚本实证的 `GetCurrentProductionTypeHash()`。不会使用 UI 专属的未来队列方法，也不会重新调用已确认不可用的 `GetNumOutgoingRoutes()`。因此 `route_coverage` 明确使用商人单位覆盖容量的代理值。

## 4. 实局验收

新局至少检查以下内容：

- 每个 AI 的两条新日志与原有 `evaluated_turn` 同步出现。
- 五个传感器成功标记均为 1；若失败，错误只出现一次且控制器继续评估。
- 所有队列类别之和等于城市数；生产切换后下一评估正确变化。
- `district_used <= district_slots` 在正常人口状态下成立；人口损失导致的暂时超槽应保留原始值。
- 商人完成或容量增加时，`route_coverage` 与 `route_pipeline` 按代理合同变化。
- 建造者完成改良后，完成覆盖率上升；仅生产建造者时只有在途覆盖率先上升。
- 战略资源接近满仓时 `strategic_full_types` 增加；消耗或升级后库存与升级积压合理变化。
- 生产、区域和转化指标不得改变 0.5.2 的扶持或焦点状态。

这些验收完成前，不为生产落后、金币结余或升级积压设置阈值，也不添加新的自动策略。
