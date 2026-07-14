# M19 合同驱动执行协议 v2

```text
CONTRACT_ID=M19-CONTRACT-DRIVEN-V2
STATUS=FROZEN_INITIAL
FACT_SOURCE=Git repository four-piece package
CHAT_HISTORY_IS_FACT_SOURCE=NO
EXECUTION_LAYER_PASS_AUTHORITY=NONE
EXTERNAL_REVIEW_REQUIRED=YES
```

## 1. 目的

本协议解决两类长期问题：反复摇摆，以及巨型任务超过执行层单次可靠注意力导致的低收敛率。后续执行固定为：

```text
永久合同 + 需求矩阵 + 缺陷账本 + 自动验收
→ 3–5 个相关缺陷组成一个波次
→ 波内 P0/P1 100% 关闭
→ 全量回归
→ commit + push
→ CANDIDATE_READY
→ 外部审查
```

## 2. 唯一事实源

仓库内四件套为唯一执行事实源：

```text
docs/m19/M19_FINAL_ACCEPTANCE_CONTRACT.md
docs/m19/M19_REQUIREMENTS.json
reports/m19/acceptance/M19_OPEN_DEFECTS.json
tests/m19/run_m19_final_acceptance.ps1
```

优先级：M19-ARCH-002 及后续明确修正 → 冻结 Runtime Master 与 manifests → 本合同和需求矩阵 → 缺陷账本 → 自动验收及仓库证据。聊天消息只用于新增/重开缺陷，不是执行事实源。

## 3. 权限

执行层只负责实现、测试、生产证据、commit、push，只能回报 `CANDIDATE_READY` 或 `HARD_BLOCKED`；无权自行 PASS、改冻结资产/坐标/产品边界、删除未关闭缺陷、用编译或文件存在证明完成。

外部审查必须通过 git clone/fetch、commit diff、真实 CI 页面和生产证据完成；执行层链接与文字只作索引。制作人只在最终联系表审查一次。

## 4. 波次制

```text
WAVE_DEFECT_COUNT=3..5
NEW_EXECUTION_SESSION_PER_WAVE=YES
WAVE_TASK_CONTENT=contract reference + defect IDs + invariants
REPEAT_FULL_REQUIREMENTS_TEXT=FORBIDDEN
```

波内 P0/P1 必须 100% 关闭；P2 仅可带明示 `QUALITY_WAIVER`。每波都必须跑全量回归。

## 5. 棘轮

每个缺陷关闭时必须同时提交修复、最小自动化测试、生产证据，并标记 `CLOSED_RATCHET`。回归套件只增不减；任何已关闭缺陷回归，本波候选整体 FAIL。

永久不变量：
- 验收入口必须是 `project.godot -> run/main_scene`；
- 六张冻结 Plate 资源与 SHA256 正确；
- 01 只显示完整 Runtime Master，不用区域裁片拼底板；
- 旧程序化 UI、旧 StyleBox、调试色块不可见；
- 必填 Fact 槽有真实数据源和可见内容；
- 02–06 可进入退出，无 Dimmer/Input/Focus/Pause 残留；
- Save schema 不变；
- 不使用 SubViewport、位图文字、幽灵数值；
- GPU 证据来自正式 Main Scene。

## 6. 根因升级线

同一缺陷 `attempt_count >= 3` 时，禁止继续补丁，必须先提交最小复现、根因分析、运行时 SceneTree、已尝试路径和外部裁决，状态设为 `OPEN_ESCALATED`。禁止用延时、重复 hide、降低阈值或新增临时状态字段绕过架构问题。

## 7. 分级

- P0：生产入口错误、无法进入退出、冻结/输入丢失、旧 UI/占位块覆盖、六页未真实显示、正式存档风险。
- P1：必填文字/变量缺失、Fact 错位/乱码、LED/列表/按钮/业务行为错误、生产证据缺失。
- P2：不影响可用性和合同结构的轻微视觉项，可明示延期；P0/P1 不允许 WAIVER。

## 8. 能力预检

每波读取/生成 `reports/m19/acceptance/CAPABILITIES.json`，至少验证正确工作树、git push、Godot GUI 捕获、GUI 输入自动化、SceneTree 快照、资产 SHA256、真实 CI 访问。未验证能力不得进入关键路径。

## 9. 生命周期

```text
读合同 → 读本波 OPEN 缺陷 → 预检 → 实现 → 波内测试 → 全量回归
→ 正式 Main Scene GPU 证据 → commit → push → CANDIDATE_READY
→ 外部 git 审查
```

## 10. 完成法理

编译通过、Shell 显示、截图生成、测试子场景通过、节点存在，都不等于需求完成。P0/P1 的 99/100 等于 FAIL。只有 Git 中代码、测试和生产证据共同通过，才能关闭波次；最终 PASS 归外部审查与制作人视觉冻结。
