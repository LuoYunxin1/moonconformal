# 选题与语义查重记录

日期：2026-11-09。使用已安装 osc2026-guide 的 Project Research Guide；赛事规则沿用 builder 固定要求。MoonCakes `moon search KEYWORD --limit 100 --json`；GitHub repositories/code API `per_page=100`；官方 moonbitlang/awesome-moonbit；完整项目登记表重新读取并以排他锁预留。以下是有界检索结论，不是官方查重裁决。

## 需求与候选比较

|候选领域|实际任务和成熟依据|核心与验收|结论|
|---|---|---|---|
|MoonConformal，统计学习不确定性|回归服务需要逐样本预测区间；多分类推理需要可变大小标签集合；ML 平台需要组别覆盖/效率诊断。MAPIE、CQR、APS 文献证明工作流成熟；未假设参与者已有使用经验|输入外部模型的校准预测与真值，执行有限样本秩修正，输出区间/集合；用独立 Python 秩枚举和边界不变量验收|通过，选择|
|时间序列离线变点|遥测/信号/实验数据分段；ruptures 的代价模型和动态规划为基线|分段点和代价，参考求解器对照|已有 Zy789kl/moon-change-point@0.3.1 与 clbbbb/bayes-shift；直接重合，淘汰|
|GNSS RINEX 接收检查|测站数据接收质量，RINEX 标准|固定宽度历元、时间窗、缺测报告|xuting22/rinex@0.1.2 实际 checker.mbt/checker_wbtest.mbt 已覆盖；淘汰|
|有序树编辑距离|AST/文档结构距离，APTED 基线|树距离与编辑路径|mooncakes 的 mizchi/similarity 已声明 APTED；其 GitHub 默认仓库现为 Rust，未据此声称检查到当前 MoonBit 源码；保守淘汰，不继续实现|

通过候选的八项评分（广度、用户、复用、低重合风险、深度、可验证性、可行性、维护，各1–5）：MoonConformal 4/4/5/4/4/5/4/4=34。另三者存在硬失败，不用分数抵消。NRRD、Zernike、HVAC、QOI、最优传输等探索项因已知近邻未进入实现候选。

## MoonConformal 范围

最小完整核心：split absolute/scaled residual、CQR/asymmetric、LAC/APS/RAPS、保守 p 值、Mondrian、CV+ 候选区间、覆盖与集合大小统计及可校验状态快照。模型训练、神经网络推理、数据清洗、任意数据条件覆盖、在线漂移适应及权重移位保证不在范围。统计假设和无穷区间必须显式表达，不能用截断校准分位数伪造有限结果。

## 实际查询

英文/缩写：conformal prediction、nonconformity、prediction interval、prediction set、MAPIE、calibration、quantile regression、jackknife、uncertainty、APS RAPS、mondrian；中文语义与登记表：保形/共形、非一致性、预测区间、校准、分组覆盖。候选查询：changepoint、ruptures、pelt、rinex、tree edit、similarity。MoonCakes limit100 返回相关片段；GitHub repositories 的 conformal MoonBit 返回11条，主要为 conformance 噪声，nonconformity/MAPIE/prediction-set/quantile-regression 精确查询0条，均 incomplete_results=false。代码搜索单独记录，不能把零结果当唯一性证明。原始响应、树SHA、源码副本与失败HTTP状态保存在仓库外验收证据中。

## 近邻语义矩阵

|项目与版本|实际查看材料|已有核心|与本项目的边界|
|---|---|---|---|
|[moonisotonic@0.1.0](https://github.com/kekeshuo/moonisotonic)|README、完整接口、quantile.mbt、band.mbt、band_wbtest.mbt、完整登记指纹|加权单调拟合、经验分位数包络|其测试明确为经验包络；不执行独立校准集 +1 秩修正及预测集合。拟合器可作为本库外部预测来源，不能代替保形后处理|
|[moon-experiment@0.2.3](https://github.com/pla678889/moon-experiment)|树、README、metrics/intervals.mbt、simulation/calibration.mbt|均值/比例/率的 A/B 参数置信区间，重复实验检验校准|目标是统计量，不是新观测的残差秩/多分类集合|
|[moon-certified@0.1.1](https://github.com/Juwan-Hwang/moon-certified)|confidence_interval、bootstrap 源码和内嵌测试|t/卡方/Wilson、bootstrap/BCa 参数区间|共享排序/分位数原语，未见保形集合工作流|
|[robust_stats@0.2.2](https://github.com/hxiuzheng/moon-robust-stats)|完整接口及 probabilistic、regression、classification_calibration、calibration_advanced、model_validation、production_surface_test|bootstrap/jackknife 均值、参数化线性回归预测区间、F1阈值/ECE|不是 held-out conformal 秩修正。初始搜索链接 robust_stats 返回404，从官方manifest恢复实际仓库链接，未将404当无项目|
|[moon-change-point@0.3.1](https://github.com/Zy789kl/moon-change-point)|README、树、detector/calibration|时间流检测、阈值F1选择|不是分类概率向量到有限样本集合|

独立建设理由：核心状态是已冻结非一致性分数、置信水平相关秩和样本外集合，而非任一近邻的拟合模型或参数估计状态。API 可接收这些项目的预测，不需绑定其训练器，也不修改其原始语义；因此独立无依赖后处理库比在其中一个拟合器加入专属扩展更易复用。

完整登记表的 reserved/completed/rejected/external-checked 按能力扫描；MoonNormal/MoonIndex 为同账号已交付但不同工作流。MoonBench、MoonContract、MoonRecur、MoonShard 强制边界全部排除；MoonIsotonic、MoonBelief、MoonIRT 完整匹配指纹另存核对。原子预留只追加，不覆盖其他记录。

限制：搜索摘要可能缺失或陈旧，GitHub 索引并非全部源码，登记表不含所有未公开项目。官方清单只是一个入口；未运行近邻项目测试，不宣称其正确性或完整性。在已记录检索范围内未发现成熟直接替代，发布前须再做核心接口反向检索。

## 发布前反向复核（2026-11-09）

最初 conformal MoonBit 代码搜索实际有 7 项，均来自 trkbt10/grib2_mbt；其中 decode/code_tables_section3.mbt 已逐项读取，命中为 Lambert Conformal 地图投影，不是保形预测。没有把这 7 项写成零结果。反向搜索 conformal_rank、nonconformity、精确 calibrate_classifier，各 per_page=100，均 total_count=0 且 incomplete_results=false；原始响应保存在仓库外。该结论仍受公开索引边界约束。
