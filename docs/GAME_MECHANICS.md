# 游戏机制与原版 AI 证据

## 1. 研究范围与证据等级

本项目以《文明 VI：风云变幻》最终规则集为基线。结论按可信度排序：

1. 本机游戏 XML/SQL/Lua：用于确认实际表结构、数值和可调用接口。
2. 官方手册与 Civilopedia：用于解释规则和玩家可见机制。
3. Mod 源代码与作者说明：用于理解可实现路线。
4. 攻略和玩家评论：用于提出测试假设，不单独作为实现事实。

任何无法在文件或运行日志中证明的行为，都不得写成“AI 一定会这样做”。

## 2. 为什么《文明 VI》容易滚雪球

### 2.1 城市、人口与区域

城市数量扩大可工作的地块、区域槽位、生产队列和胜利资源来源。专业区域数量受人口门槛限制，通常在 1、4、7 人口并继续每 3 人增加一个；引水渠、社区和宇航中心不计入该上限。因此，移民、粮食、住房和宜居度不是独立指标，而是后续科技、文化、金币、军力和胜利项目的共同底座。

住房不足会抑制人口增长。宜居度影响城市增长与全部非食物产出：快乐和欣喜若狂提供增长与产出加成，欠缺宜居度则会降低效率，严重时停止增长。动态控制器若只看到“科技落后”而让 AI 继续造学院，可能掩盖真正的住房、宜居度或人口问题。

### 2.2 改良设施与建造者

人口只有在存在可工作的高质量地块时才能转化为产出。原版 AI 使用 `PSEUDOYIELD_IMPROVEMENT` 等伪产出来估算改良价值，但游戏文件明确说明，伪产出主要服务 AI、灵活性较低，而且绝大多数在引擎中被特殊处理。修改权重通常会影响决策，但不能保证线性效果，也不能把数值直接解释成“提高了多少概率”。

### 2.3 贸易路线

贸易路线同时承担道路、金币、粮食、生产、外交和旅游修正。路线容量主要来自商业中心或港口的相应建筑，同城同时建两类区域通常不会重复增加同一档容量。目的地拥有的区域会改变路线收益。因此，“没有商人”可能来自容量、生产队列、目的地价值或战争安全，而不只是商人权重太低。

### 2.4 科技、市政与触发加速

科技和市政不仅取决于每回合科学、文化，也受尤里卡、鼓舞、城市专精、人口和扩张节奏影响。只比较瞬时产出会漏掉已完成科技/市政数量和加速触发，故感知层至少要同时保存存量、流量与趋势。

### 2.5 胜利转化

- 科技胜利在风云变幻中依次需要卫星、登月、火星基地和系外行星探索，之后可用激光项目加速。高科学但不建设宇航中心、不完成项目，不构成实际威胁。
- 文化胜利要求来访游客超过每个对手的国内游客。巨作、遗物、国家公园、奇观、开放边境和国际贸易等都会影响旅游转化；高文化只提高防御和市政推进，不等同于正在赢得文化胜利。
- 统治胜利取决于控制原始首都。高军力若不能组建合适的攻城队伍、选择目标并完成城市行动，也不会转化为胜利。

因此，目标系统必须区分“能力强”与“正在有效推进胜利”。

## 3. 原版难度实际做了什么

### 3.1 数值优势而非完整的更聪明 AI

`Base/Assets/Gameplay/Data/Leaders.xml` 通过 `LinearScaleFromDefaultHandicap` 为高于王子的每一档难度增加 AI 修正。每档大致增加：

| 项目 | 每档增量 | 神级相对王子（4 档） |
| --- | ---: | ---: |
| 科技、文化、信仰 | 8% | 32% |
| 生产力、金币 | 20% | 80% |
| 战斗力 | 1 | 4 |
| 经验 | 10% | 40% |

`Eras.xml` 还定义高难度 AI 的额外开局单位。远古开局的主要文明本来拥有 1 移民、1 战士；高难度逐步加入战士、建造者和移民。风云变幻所加载的 `Expansion1_Leaders.xml` 删除了更早版本的免费科技/市政加速，但开局单位和持续产出修正仍在。

结论：原版神级的前期强势主要来自前置资产和持续倍率，不能等同于其后期决策质量更高。

### 3.2 游戏速度

`GameSpeeds.xml` 的成本倍率为：马拉松 300、史诗 150、标准 100、快速 67、联机 50。任何“每 5 回合检查”“持续 10 回合”的逻辑若不换算速度，会在联机速度上反应过慢，在史诗/马拉松上反应过快。

## 4. 原版 AI 的可修改层

### 4.1 Strategy 与 StrategyConditions

`Victories.xml` 定义科技、文化、军事、宗教、扩张等策略及其条件。条件可以检查时代、科技领先、军力、战争、适合定居的位置、伟人、奇观和旅游等状态。`Strategy_Priorities` 再将策略连接到一个或多个 `AiList`。

这套系统是“启用某组偏好”，不是脚本直接命令 AI 完成某个动作。即使策略正确激活，最终行为仍要经过引擎估值、城市队列、资源、地形、行动编组和战术执行。

### 4.2 AiLists

原版可见的列表系统包括：

- `Yields` 与 `PseudoYields`
- `Districts`、`Buildings`、`Projects`、`Technologies`、`Civics`
- `AiOperationTypes`、`TriggeredTrees`
- `DiplomaticActions`
- `PlotEvaluations`、`SettlementPreferences`

最终数据库中没有可由同一列表系统可靠控制的通用 `Policies` 项，因此目前不能声称通过添加一个列表就能动态指定政策卡。

### 4.3 建造专精

原版提供防御、文化、信仰、粮食、金币、生产、科技、军事和贸易等 `AiBuildSpecializations`。它们适合作为“当前城市/文明需要什么”的高层信号，但仍需要验证具体列表是否被当前规则集和引擎消费。

### 4.4 军事行动与行为树

`Operations.xml` 定义行动目标、搜索距离、胜算阈值、最低单位数和行为树。例如围墙城市行动比普通目标需要更明确的攻城编成。`BehaviorTrees.xml` 负责申请单位、等待编组、移动到目标、围城、攻击和劫掠。

城市强度与最强近战单位、驻军和区域有关，城墙对不同攻击类型的承伤效率也不同；被围城会停止治疗。于是军事问题至少分成：

- 是否生产正确角色的单位。
- 是否升级并保留战略资源。
- 是否能形成行动编组。
- 是否选择可达且值得的目标。
- 是否能在战术层保持攻城单位、近战占城单位和支援单位的协同。

简单提高“军事伪产出”可能只制造更多单位，甚至恶化维护费和拥堵，不能证明 AI 更会打仗。

## 5. Mod 能力边界

通过数据库和 Lua，本项目能够：

- 添加/激活策略，修改其 `AiList` 权重。
- 调整伪产出、单位编成、行动类型、建造专精和部分胜利偏好。
- 定期读取公开玩家、城市、单位和游戏状态，保存自定义属性并写日志。
- 修改显式难度倍率和开局单位，但默认产品不把它们作为动态控制手段。

本项目不能可靠做到：

- 重写闭源 DLL 内的寻路、战术单位控制、目标估值和全部城市生产逻辑。
- 保证一个权重变化必然产生某个动作，或用权重差直接推导概率。
- 通过不存在或未被消费的列表控制政策卡。
- 完全消除其他 Mod 对同一 AI 表、行为树和 Lua 事件的覆盖冲突。

## 6. 对设计的直接结论

1. 实力评估不能只用一个总分，必须保存科技、文化、人口/城市、基础设施、军事和胜利转化等支柱。
2. 产出倍率与决策质量应分层。默认动态层只动决策；静态难度曲线应可独立开关和测试。
3. 军事评估不能只累加单位基础战斗力，需要逐步加入兵团/军队、生命、升级、角色、资源、战争目标和城市攻占结果。
4. 使用趋势和平滑窗口，按标准速度等效回合进行检查、滞回和冷却。
5. 每个干预都要记录输入、状态、激活列表和持续时间，不能从结果倒推“权重一定生效”。
6. 中后期测试必须检查实际胜利里程碑，而不是只比较每回合科技和文化。

## 7. 主要来源

本机文件：

- `Base/Assets/Gameplay/Data/Schema/01_GameplaySchema.sql`
- `Base/Assets/Gameplay/Data/Victories.xml`
- `Base/Assets/Gameplay/Data/Operations.xml`
- `Base/Assets/Gameplay/Data/BehaviorTrees.xml`
- `Base/Assets/Gameplay/Data/Yields.xml`
- `Base/Assets/Gameplay/Data/Leaders.xml`
- `Base/Assets/Gameplay/Data/Eras.xml`
- `Base/Assets/Gameplay/Data/GameSpeeds.xml`
- `DLC/Expansion2/Data/Expansion1_Leaders.xml`
- `DLC/Expansion2/Data/Expansion2_AI.xml`
- `DLC/Expansion2/Data/Expansion2_Victories.xml`

在线资料：

- 官方在线手册：<https://cdn.cloudflare.steamstatic.com/steam/apps/289070/manuals/CIV_VI_25TH_ONLINE_MANUAL_ENG.pdf?t=1663263035>
- Civilopedia 城市与区域：<https://www.civilopedia.net/en-US/gathering-storm/concepts/cities_10/>
- Civilopedia 住房：<https://www.civilopedia.net/en-US/gathering-storm/concepts/cities_14/>
- Civilopedia 宜居度：<https://www.civilopedia.net/en-US/gathering-storm/concepts/cities_16/>
- Civilopedia 贸易路线：<https://www.civilopedia.net/en-US/gathering-storm/concepts/trade_2/>
- Civilopedia 城市战斗：<https://www.civilopedia.net/en-US/gathering-storm/concepts/combat_9/>
- Civilopedia 文化胜利：<https://www.civilopedia.net/en-US/gathering-storm/concepts/victory_4/>
- 社区神级攻略（仅作玩法假设）：<https://steamcommunity.com/sharedfiles/filedetails/?id=2367352890>
