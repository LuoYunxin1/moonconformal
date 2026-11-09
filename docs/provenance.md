# 参考、许可与 AI 使用

本项目独立编写算法和测试。实现未复制上游源码、测试数据或文档，未将上游版权作品改名提交。以下材料用于确认数学语义和成熟工作流：

- Angelopoulos 与 Bates，A Gentle Introduction to Conformal Prediction and Distribution-Free Uncertainty Quantification：<https://arxiv.org/abs/2107.07511>。
- Romano、Patterson 与 Candès，Conformalized Quantile Regression：<https://arxiv.org/abs/1905.03222>。
- Romano、Sesia 与 Candès，Classification with Valid and Adaptive Coverage：<https://arxiv.org/abs/2006.02544>。
- Barber 等，Predictive inference with the jackknife+：<https://arxiv.org/abs/1905.02928>，CV+ 端点与保证需按折条件阅读。
- MAPIE：<https://github.com/scikit-learn-contrib/MAPIE>，BSD-3-Clause。查看 README、LICENSE、utils 和 APS 分数实现，用于核对范围；本库不提供 MAPIE 训练器、随机化评分或 sklearn API 兼容层。

MoonBit 标准核心库为 Apache-2.0，与本仓库 MIT 许可兼容；项目没有外部 MoonCakes 依赖。CI checkout Action 为独立构建工具，不打入发布模块。

AI 辅助参与选题研究、初稿实现、测试、文档和调试。测试预期以独立公式枚举、不同构造的分类评分、边界不变量核对，代码审查不把 AI 自述当验证证据。示例为合成模型预测，不声称真实临床、金融或生产部署。申报书和私人验收材料保存在仓库之外，不作为模块内容发布。
