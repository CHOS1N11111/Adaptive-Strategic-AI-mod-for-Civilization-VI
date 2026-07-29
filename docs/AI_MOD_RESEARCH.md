# 现有 AI Mod 调研

## 1. 调研方法

本调研区分三类证据：

- **源代码/数据库事实**：可以确认实现了什么，优先级最高。
- **作者声明**：能说明设计意图，但仍需实测验证效果。
- **社区反馈**：用于寻找风险和测试场景，不代表稳定复现的结论。

“AI 更难”可能来自更好决策，也可能只来自额外产出、单位或战斗修正。比较时必须把这两者拆开。

## 2. 横向比较

| Mod | 主要路线 | 玩家相对动态调整 | 直接补助 | 主要价值 | 主要局限与风险 |
| --- | --- | --- | --- | --- | --- |
| Real Strategy | Lua 计算战略、胜利倾向、地理与局势，再激活 AiLists | 有部分世界平均追赶/充足状态 | 以决策权重为主 | 战略状态、胜利路线、日志和持久化完整 | 不能改闭源战术；部分列表/回调存在可靠性疑点 |
| RomanHoliday's AI Rework | 大范围重写策略、行动、行为树、编成、外交与胜利路线 | 否 | 作者称基本不改常规难度产出 | 当前最全面的行为层参考之一 | 与同类行为 Mod 高冲突；不是玩家相对控制器 |
| Late Game AI | 难度倍率随时代增强，兼有军事调整 | 只随时代，不看玩家 | 是 | 直接解决“前期较弱、后期压力不足”的难度曲线 | 可能制造不依赖局势的后期失控与极端产出 |
| AI+ | 早期 XML 行为和权重调校 | 否 | 主要为行为调校 | 证明无 DLL 也可调整多类 AI 行为 | 年代较早，兼容性和当前规则适用性有限 |
| Better AI Tweaks | 在 RHAI 上追加伪产出、行动、城防和战争补丁 | 否 | 有针对性单位/战斗调整 | 展示对具体战争症状的补丁方法 | 社区报告过编成偏斜、移动与不同速度问题 |
| Smoother Difficulty 2 | 移除部分前期开局优势，按时代增加科技/文化/旅游 | 只随时代 | 是 | 平滑原版前强后弱的难度曲线 | 静态曲线无法识别具体 AI 与玩家差距，版本较旧 |
| Adaptive Difficulty | 根据人类行为、外交和战争给各 AI 动态单位/产出 | 是 | 是 | 与本项目名称上最接近的前例 | 即时刷兵与补偿会削弱公平感，作者目标是“更难”而非“更聪明” |

## 3. Real Strategy

来源：

- 代码：<https://github.com/Infixo/Civ6-Real-Strategy>
- Steam：<https://steamcommunity.com/sharedfiles/filedetails/?id=1617282434>
- 系统说明：<https://github-wiki-see.page/m/Infixo/Civ6-Real-Strategy/wiki/Systems>
- CivFanatics 更新：<https://forums.civfanatics.com/resources/real-strategy-ai.27195/updates>

### 3.1 可借鉴点

Real Strategy 把 AI 行为组织成可持久化的 Lua 战略状态，并用 `AiLists` 影响胜利、扩张、军事、地理和建造选择。其胜利策略不只看一个分数，还综合已知世界平均值、文明/领袖偏好、政府、政策、奇观、伟人、宗教和地理。

它已实现若干局势状态：

- 军力低于已知世界平均约 60% 时进入追赶。
- 军力高于平均约 220% 时认为充足。
- 科技数量低于世界平均约 90% 并额外落后一定数量时偏向科技。
- 文化产出低于世界平均约 80% 时偏向文化。

策略检查会根据游戏速度成本倍率换算，并让状态保持若干标准速度等效回合。这证明“感知 -> 状态 -> AiList -> 持久化/日志”是可行的基础结构。

### 3.2 不能直接照搬的地方

- 世界平均不等于人类对手水平，且会被极强或极弱文明扭曲。
- 其追赶列表主要改变军事、防御、奇观、区域和改良权重，未必能修复具体的科技、文化或人口根因。
- 本地检查的 2.3.1 源码中，科技与文化追赶回调更新并保存状态，但与其他回调不同，未看到显式返回激活布尔值。这是需要运行时验证的源代码风险，不能直接断言对应策略稳定生效。
- 项目说明与代码中存在被标记为 `BUGGED` 的偏好项，说明并非所有暴露列表都能被引擎可靠消费。
- 它仍受闭源战术与寻路限制；战略正确不代表城市进攻一定成功。

### 3.3 对本项目的启示

保留其状态机、速度归一化、持久化和可观察性；将单一世界平均改为人类参考、世界分布和 AI 个体趋势的组合；每个回调必须有明确的失败关闭和返回值测试。

## 4. RomanHoliday's AI Rework

来源：<https://steamcommunity.com/workshop/filedetails/?id=3019772473>

作者描述的范围包括内部策略、胜利路线、军事行动、行为树、单位编成、城市进攻、忠诚度、空军、海军、定居与外交。作者明确声明普通科技、文化、信仰和生产难度倍率基本不由本 Mod 改动，额外单位/资源只用于少量针对性问题。

这是行为优先路线的重要参考：先修“会不会做”和“如何转化”，再决定是否需要数值优势。它也说明同一表和行为树的所有权很重要：作者明确提示与 Real Strategy、AI+ 等全面行为 Mod 不兼容，而可与以时代倍率为主的 Late Game AI 配合。

本项目应学习其问题拆分和行动编组，不应假定能与它同时接管相同层。长期可考虑提供 `RHAI compatibility/controller-only` 版本，但必须通过明确的所有权矩阵实现，不能只写“兼容”。

## 5. Late Game AI 与 Smoother Difficulty 2

来源：

- Late Game AI Steam：<https://steamcommunity.com/sharedfiles/filedetails/?id=2939752243>
- Late Game AI CivFanatics：<https://forums.civfanatics.com/resources/late-game-ai.30043/>
- Smoother Difficulty 2：<https://steamcommunity.com/sharedfiles/filedetails/?id=1673479392>

两者都抓住原版难度曲线的真实问题：额外开局资产造成前期压力，而固定倍率未必让后期 AI 有有效竞争力。它们用时代曲线削弱前期、强化后期，容易理解，也容易制造明显效果。

但时代不是实力。如果某 AI 已经凭领土和外交领先，继续获得同等时代增幅会加剧失控；如果某 AI 因战争只剩两城，时代加成也未必能恢复决策链。社区对 Late Game AI 的反馈中出现过极端科技/文化产出和失控文明，这些反馈只能作为测试风险，但足以说明静态全局倍率不能承担本项目的默认动态控制。

结论：保留“前期不过强、后期仍有压力”的曲线目标，但把静态难度层与实时决策层彻底分开。

## 6. Better AI Tweaks 与 AI+

来源：

- Better AI Tweaks：<https://steamcommunity.com/sharedfiles/filedetails/?id=3256128675>
- AI+：<https://steamcommunity.com/sharedfiles/filedetails/?id=878717347>

AI+ 是较早的无 DLL 行为调校尝试，也明确警告多个 AI Mod 同时覆盖相同定义可能产生冲突。Better AI Tweaks 建立在 RHAI 之上，追加战争倾向、行动、城防、伪产出、围城伤害和经验等针对性补丁。

其价值在于把“AI 不会打仗”拆成具体症状；风险在于补丁容易过拟合。社区反馈提到攻城/防空单位偏多、超大地图或马拉松速度下移动表现异常、存档兼容问题。它们不是可靠的总体结论，但应转化为本项目测试项：单位角色占比、维护费、拥堵、地图大小、速度归一化和中途更新读档。

## 7. Adaptive Difficulty

来源：

- Steam：<https://steamcommunity.com/sharedfiles/filedetails/?id=1321145052>
- Infixo 对其路线的讨论：<https://forums.civfanatics.com/threads/real-strategy-ai.640452/page-2#post-15326299>

该 Mod 会依据人类行为、外交和战争，为不同 AI 动态授予单位或产出。作者自己的表述更接近“让人类更难取胜”，而不是提高 AI 决策能力。社区反馈中出现玩家回合内突然生成援军和补偿过强的问题。

它是本项目最重要的反例：自适应逻辑虽然可以做到个体化和实时化，但若干预直接、即时且与玩家行为绑定，就会让玩家无法信任正常的资源、战损与外交反馈。

本项目据此确定三条红线：默认不刷兵、不复制产出、不把宣战或击杀直接变成 AI 奖励。

## 8. 动态难度研究对设计的约束

动态难度研究普遍把目标描述为维持挑战与技能匹配，但也指出不透明调整可能降低控制感，让玩家觉得系统在作弊。Robin Hunicke 特别强调：若动态调整破坏游戏核心反馈或在最后时刻强行“橡皮筋”，玩家会感到被欺骗；系统必须先定义目标、可干预量、阈值、步长和延迟。

相关研究：

- Hunicke, *The Case for Dynamic Difficulty Adjustment in Games*：<https://www.researchgate.net/profile/Robin_Hunicke/publication/220982524_The_case_for_dynamic_difficulty_adjustment_in_games/links/53fb98490cf2dca8fffe800a.pdf>
- Zohaib, 2018 综述：<https://doi.org/10.1155/2018/5681652>
- Ang & Mitchell, 2017：<https://doi.org/10.1145/3116595.3116623>
- Denisova & Cairns, 2015：<https://cronfa.swansea.ac.uk/Record/cronfa39565>

对本项目的直接要求是：调整低频、有限、可解释；保留玩家因果反馈；不追求每时每刻比分接近；同时评估挑战和控制感，而不只统计 AI 胜率。

## 9. 综合结论

目标方案不是把几个 Mod 的数值相加，而是组合其最有效的思想：

- 借鉴 RHAI 对策略、行动编组和胜利转化的细分。
- 借鉴 Real Strategy 的 Lua 状态机、个体诊断、游戏速度换算和日志。
- 接受 Late Game AI 指出的难度曲线问题，但不使用无条件的全局后期爆发作为默认解法。
- 用 Better AI Tweaks 暴露的编成、速度和存档问题建立回归测试。
- 明确拒绝 Adaptive Difficulty 式即时刷兵和玩家动作补偿。

在完成固定种子 A/B 测试前，本项目只能称为“有不同设计目标”，不能宣称已经全面优于这些 Mod。
