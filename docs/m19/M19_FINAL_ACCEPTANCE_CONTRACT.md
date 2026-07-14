# M19 合同驱动执行协议 v2

```text
CONTRACT_ID=M19-CONTRACT-DRIVEN-V2
CONTRACT_VERSION=v2.2
STATUS=ACTIVE
SUPERSEDES=v2.1
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

## 5. 三层门禁制 (v2.2)

### 5.1 FAST_GATE
每次普通代码迭代执行。目标耗时 ≤3 分钟。
执行项：全部 GDScript 解析 / production purity 扫描 / 受影响核心服务单测 / 关键 UI 节点存在 / 一次真实点击 smoke / 一次保存写入 smoke / 本次变更对应的单个缺陷测试。
禁止项：250 次 Modal / 17 张截图 / 10 分钟 F5 / 三轮跨进程重启 / 全历史回归 / 完整 GPU 证据包。

### 5.2 WAVE_GATE
每个 Wave 报告 CANDIDATE_READY 前执行一次。
执行项：本波所有缺陷测试 / 所有现存 ratchet / 本波真实业务路径 / 本波最终证据 / production purity / save schema diff / worktree clean / local/remote match。

### 5.3 MILESTONE_GATE
整个里程碑封口时只运行一次。
执行项：02–06 各 50 次 Modal (共 250 次) / 三轮跨进程保存-退出-重启 / ≥17 张最终截图 / 正常 F5 10 分钟 / 完整历史回归 / Windows GPU 正式证据 / 最终联系表 / 最终 evidence commit。

## 6. 棘轮 (v2.2 修订)

每个缺陷关闭时必须同时提交修复、最小自动化测试、生产证据，标记 `CLOSED_RATCHET`。

棘轮成本约束：
- 单个运行时间 ≤10 秒 / 无 GUI / 无截图 / 无长时间 sleep / 无完整进程重启
- 只验证对应缺陷的确定性不变量

禁止进入棘轮：Modal 压力测试 / GPU 截图 / F5 10 分钟 / 三轮跨进程存档 / 全量历史回归（属于 MILESTONE_GATE）。

回归套件只增不减；任何已关闭缺陷回归，本波候选整体 FAIL。

永久不变量（同 v2.1 §5）。

## 7. 脚手架单例约束

仓库只允许四个 active 入口：GUI Runner / Data Runner / Cross-process Orchestrator / Ratchet Aggregate Runner。每个类别唯一 canonical path。新增第二个同类实现=P0 缺陷。

## 8. 证据纪律

普通迭代：截图/JSON/日志进 CI artifacts 或临时目录，不进 Git。Wave 候选：Git 只保留该 Wave 一份最终证据包。Milestone：Git 只保留一份最终证据包。

## 9. 根因升级线

同 v2.1 §6。

## 10. 分级

同 v2.1 §7。

## 11. 能力预检

每波读取/生成 `reports/m19/acceptance/CAPABILITIES.json`，至少验证正确工作树、git push、Godot GUI 捕获、GUI 输入自动化、SceneTree 快照、资产 SHA256、真实 CI 访问。未验证能力不得进入关键路径。

## 9. 生命周期

```text
读合同 → 读本波 OPEN 缺陷 → 预检 → 实现 → 波内测试 → 全量回归
→ 正式 Main Scene GPU 证据 → commit → push → CANDIDATE_READY
→ 外部 git 审查
```

## 10. 完成法理

编译通过、Shell 显示、截图生成、测试子场景通过、节点存在，都不等于需求完成。P0/P1 的 99/100 等于 FAIL。只有 Git 中代码、测试和生产证据共同通过，才能关闭波次；最终 PASS 归外部审查与制作人视觉冻结。
