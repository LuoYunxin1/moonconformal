# MoonConformal

纯 MoonBit 的模型无关保形预测后处理库。把外部模型的独立校准预测和真值转换为回归预测区间、多分类标签集合，并检查组别覆盖率、集合大小与有限样本分辨率。库不训练模型，不需要 Python 运行时或第三方 MoonCakes 依赖。

版本：`LuoYunxin1/moonconformal@0.1.0`；许可证：MIT。

## 用途与实际工作流

- 回归服务：输入未参与训练的校准真值、点预测或上下分位数，输出普通、按尺度归一化、CQR 或非对称尾区间；可保留无界区间与空集合。
- 分类审核系统：输入概率矩阵与校准标签，使用 LAC、确定性 APS 或 RAPS 产生可变大小标签集合与保守 p 值；可按单标签/多标签结果分派人工审核。
- 模型评估平台：固定组别分别校准；接收交叉验证模型的样本外预测构造 CV+ 区间；检查联合多输出覆盖与各维边际覆盖；快照可在服务间迁移。

三个完整工作流在 `examples/regression`、`examples/classification` 和 `examples/platform`。数据为可复现的合成预测，代表接口接入方式；没有虚构真实用户部署或实测业务收益。

## 环境与安装

开发及 CI 固定 `moonc v0.10.18+6c83a7f62`，高于赛事要求的 0.10.16；`moon` 为 0.1.20261028。支持 `wasm-gc`、`wasm`、`js`、Linux `native`。JS 需要 Node.js；native 需要 GCC/Clang。Windows 开发可使用 wasm-gc/wasm/js，Linux native 可用 WSL 或 CI 复现。

在已有 MoonBit 项目目录中安装精确版本：

```sh
moon add LuoYunxin1/moonconformal@0.1.0
```

在消费者的 `moon.pkg` 中导入：

```moonbit
import {
  "LuoYunxin1/moonconformal" @conformal,
}
options(is_main: true)
```

创建 `main.mbt`：

```moonbit
fn main {
  try {
    let scores = @conformal.absolute_scores(
      [1.0, 2.0, 3.0, 4.0],
      [0.0, 0.0, 0.0, 0.0],
    )
    let intervals = @conformal.predict_absolute(scores, [10.0], 0.2)
    println(@conformal.intervals_to_json(intervals))
  } catch {
    _ => abort("calibration failed")
  }
}
```

运行 `moon run .`，结果中的 `lower=6`、`upper=14`（JSON 对象键序不作为契约）。把 alpha 改为 0.1 时，有限样本校正会要求超出已有数据的秩，得到 `"-inf"` 与 `"+inf"`；不会悄悄返回样本最大值。

从源代码运行：

```sh
git clone https://github.com/LuoYunxin1/moonconformal.git
cd moonconformal
moon run examples/regression
moon run examples/classification
moon run examples/platform
```

Linux x86_64 可以执行 `bash scripts/install-toolchain.sh /tmp/moonconformal-toolchain` 安装固定工具链，随后设置 `MOON_HOME`、`MOON_TOOLCHAIN_ROOT` 为该目录，并把其 `bin` 加到 PATH。安装器要求新目录并校验两个官方归档的 SHA-256，不更改全局登录或系统配置。

## 核心接口

|场景|校准|预测/诊断|
|---|---|---|
|普通 split conformal|`absolute_scores(truth, prediction)`|`predict_absolute(scores, query, alpha)`|
|异方差尺度|`scaled_scores(truth, prediction, scale)`|`predict_scaled(scores, query, query_scale, alpha)`|
|CQR 分位数回归|`cqr_scores(truth, lower, upper)`|`predict_cqr(scores, query_lower, query_upper, alpha)`|
|不对称尾|`tail_scores(truth, prediction)`|`predict_tails(scores, query, alpha, low_fraction)`|
|多分类|`calibrate_classifier(rows, labels, Lac/Aps/Raps(lambda,k))`|`model.predict(rows, alpha)`、`model.p_values(rows)`|
|固定组别 Mondrian|`grouped_scores(values, group_names)`|`predict_grouped_absolute`、`groups.get(name)`|
|CV+|`cvplus_calibrate(truth, out_of_fold, fold_ids, folds)`|`model.predict(test_by_fold, alpha)`|
|多输出联合矩形|`calibrate_vectors(truth, prediction, scales)`|`model.predict(query, query_scales, alpha)`|
|自定义非一致性|`Scores::new(values)`|`threshold`、`p_value`、`select_by_p_value`|
|评估|`evaluate_intervals`、`evaluate_sets`|`evaluate_grouped_intervals`、`evaluate_vectors`|
|分辨率|`scores.resolution(alpha)`|`minimum_calibration_count(alpha)`、`threshold_path`、`interval_path`|
|状态/结果交换|`to_snapshot` / `from_snapshot`|`intervals_to_json/from_json`、`sets_to_json/from_json`|

`Scores`、`ClassCalibrator`、`GroupScores` 的状态不可变，数组访问返回副本。`DataSplit` 检查训练/校准/评估索引唯一且互斥，并按原有顺序选择值；它不能检查外部训练器是否实际遵守划分。

分类示例（放在 `try` 块内，完整可运行入口见 `examples/classification/main.mbt`）：

```moonbit
let model = @conformal.calibrate_classifier(
  [[0.8, 0.2], [0.6, 0.4], [0.7, 0.3], [0.9, 0.1]],
  [0, 0, 0, 0],
  @conformal.Lac,
)
let sets = model.predict([[0.7, 0.3]], 0.2)
println(@conformal.sets_to_json(sets, 2)) // rows=[[0]]
```

## 统计语义与限制

`alpha` 是失覆盖水平，严格在 `(0,1)` 内。split 方法要求模型、尺度、分组规则与超参数选择独立于校准标签，并要求校准样本和待预测样本满足适用的可交换性条件；本库验证数值和形状，不能验证数据生成过程。数据依赖调参、分布漂移、时间相关性或反复选择最有利 alpha 会破坏通常的覆盖解释。经验评估不构成理论保证。

非一致性越大越不匹配。校正秩在精确实数下为 `ceil((n+1)*(1-alpha))`；实现直接比较离散网格 `k/(n+1)` 与输入 Double，避免 `1-alpha` 抵消使边界偏一。秩 `n+1` 表示正无穷。保守 p 值为 `(1 + count(calibration_score >= candidate))/(n+1)`，所有并列值都计入；集合选择 `p > alpha`，p 值不是类别概率。

CQR 的 `max(lower-y, y-upper)` 可为负，不截零；校正后端点交叉表示合法空集合。非对称方法将总 alpha 分配给两尾，用联合界解释总失覆盖；乘法下溢为零会明确报错。

APS 按概率递减、标签索引递增排序，分数包含候选本身的完整概率；没有随机化或边界标签强制包含。RAPS 加上 `lambda*max(rank-k,0)`。该确定性约定适合保守集合，不能假装与 MAPIE 所有随机化/边界处理选项逐项相同。校准和预测必须使用相同规则、类别语义和列顺序。概率和允许绝对误差 `1e-10`，不自动重归一化。

Mondrian 在固定组内使用该组的 n；未知组报 `UnknownGroup`，小组允许无界输出。CV+ 的 `test_by_fold[j][f]` 必须来自训练时排除第 f 折的模型 f；端点采用下 `floor((n+1)*alpha)`、上 `ceil((n+1)*(1-alpha))` 的离散网格对称构造，要求 `alpha<0.5`。CV+/jackknife+ 文献的保证随算法和折条件而异，本库不宣称 CV+ 具有精确的 `1-alpha` 有限样本覆盖，也不自动重训模型。

向量方法用每行最大归一化误差校准联合矩形。不能把各维单独 90% 区间称为联合 90%。不支持在线/加权移位保形、随机 APS、模型训练、缺失值插补或任意数据上的逐点条件覆盖保证。

## 错误、资源限制与交换格式

公开失败为 `ConformalError`：`Invalid(message)`、`ResourceLimit(message)`、`UnknownGroup(name)`。非有限输入、形状不匹配、非正尺度、非法标签、交叉的基础分位数、计算溢出均报错。`Interval` 公开字段允许手工构造，评估/导出入口会再验证端点；`lower>upper` 是空集合，宽度为零。

默认单向量最多 100000 项、类别 2..1024、分组最多 10000、矩阵最多 2000000 单元。CV+ 每批最多 2000000 对候选端点；分辨率路径最多 1000 个 alpha。JSON 导入最多 4000000 UTF-16 代码单元、嵌套深度 12，拒绝重复键、未知字段、越界版本和非有限数值。导出上限遵循元素预算，大型导出可能超过导入文本预算，服务应分批传输。快照不是真实性签名，不能证明校准来源未泄漏。

状态快照 schema 为 1，类型为 `scores`、`classifier` 或 `groups`。预测 JSON schema 为 1，类型为 `intervals` 或 `sets`，无穷端点用字符串 `"-inf"` / `"+inf"`，不使用 NaN/null 替换。集合保留标签索引；类别名称由调用方管理。

## 开发与验证

```sh
moon info
moon fmt
moon fmt --check
moon check --deny-warn
moon test --deny-warn
moon build --deny-warn
python3 tools/oracle.py --target wasm-gc
```

每个目标均可用 `--target wasm-gc|wasm|js|native`。CI 对四个目标执行格式、严格检查、测试、构建、三个工作流和独立 Python 对照。Python 仅用于开发验收；Python 3.8 以上、仅标准库，发布库不依赖 Python。`python3 tools/oracle.py --generate` 可重建确定性输入，不生成参考答案。

独立对照含 320 个秩/阈值/p 值样本（含并列、网格边界和相邻 Double）、12 个分类规则样本，以及 CQR、尺度、CV+、向量四个集成结果，共 336 项。数值比较容差为 `1e-12`。该对照是公式级独立枚举与另一种分类评分构造，不冒充对 MAPIE 所有功能的兼容认证。测试另覆盖无界/空集、非法输入、状态副本、JSON 损坏和索引泄漏检查。

## 设计、来源与许可

参见 [架构与数值契约](docs/design.md)、[参考与 AI 使用说明](docs/provenance.md)、[查重范围与边界](docs/competition/duplicate-check.md) 和 [更新记录](CHANGELOG.md)。

本项目为原创实现，公开参考包括 MAPIE（BSD-3-Clause）和保形预测论文；没有复制其源码、测试数据或文档段落。仅依赖 MoonBit 标准核心库（随官方工具链提供，Apache-2.0）。本仓库采用 MIT，见 [LICENSE](LICENSE)。设计、实现、测试、文档和调试使用了 AI 编码辅助；交付内容通过可复现命令验证，统计适用条件由使用者核对。
