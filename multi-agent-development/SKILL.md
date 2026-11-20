---
name: multi-agent-development
description: Use when coordinating software development with multiple agents, independent code and UI/UX review, persistent task tracking, Git branch isolation, implement-test-review-merge cycles, AGENTS.md repository binding, or per-agent/subtask/total elapsed-time reporting. 适用于强绑定仓库多任务协同、按需调度工程师、UI/UX 验收及真实计时。
---

# Multi-Agent Development / 多 Agent 自主软件开发（V2.1）

One Skill entry and one state machine, with Chinese and English workflow references. Language affects presentation, never scheduling, quality gates, or permissions. 单一入口与状态机，中英文规则同等有效。

## Non-negotiable repository gate / 仓库强绑定门禁

**Every invocation, before product-code changes, task-state transitions or engineering dispatch:**

1. Start the Lead round clock immediately and print the **real event time converted to Tokyo time: `Asia/Tokyo` (JST, UTC+09:00)**, regardless of host/Agent timezone. Use `YYYY-MM-DD HH:MM:SS +09:00 zone=Asia/Tokyo` for every `START`/`END`/subtask timestamp. Read [repository-binding.md](references/repository-binding.md) **completely**.
2. Read the target repository root `AGENTS.md` and applicable nested instructions. Create or update **only** the uniquely marked managed block from the binding reference; preserve unrelated instructions. Persist and commit/push under existing authorization and branch policy. If this cannot safely be persisted, mark `BLOCKED` and request direction; never silently bypass the binding.
3. Record the original first start, each round's start/end/elapsed time, every Agent's and measurable subtask's timing, UI/UX review time, and total wall-clock elapsed in canonical `TASKS.md` or equivalent. **All new timestamp fields, task ledgers and user-facing reports use `Asia/Tokyo` (+09:00), even on UTC/US hosts**; convert legacy offset-aware first-start instants to JST for display while preserving their original instant/provenance. Elapsed durations are timezone-independent; never reset the first start or add parallel Agent durations to fabricate project elapsed time. Mark unknowns `NOT MEASURED`.

**每次调用都必须重检项目根目录 `AGENTS.md` 的强绑定，先将真实事件时间换算为东京 `Asia/Tokyo`（UTC+09:00）并计时，持久化约束后再派单；所有 Agent/子任务/审查/最终报告一律 JST，跨会话总历时不重置。**

## Select full workflow / 选择完整工作流

| User language / 用户语言 | Required reference / 必读 |
|---|---|
| 中文 | [workflow.zh-CN.md](references/workflow.zh-CN.md) |
| English or other | [workflow.en.md](references/workflow.en.md) |
| Explicit bilingual comparison / 双语对照 | Read both / 两份都读 |

Also read [UI/UX acceptance contract](references/ui-ux-acceptance.md) completely for any UI-affecting task or release readiness check. 对 UI 相关任务和发布验收，完整阅读 UI/UX 规范。

## Mandatory orchestration / 强制协同规则

1. **Lead = the main conversation; up to five concurrently assigned Engineers; one independent Reviewer.** The Lead determines the number of Engineers from independent ready tasks, file ownership, review capacity and actual runtime slots. **Five is a hard cap, not a target.** Ready tasks beyond available capacity go into durable `QUEUED`; never spawn a sixth Engineer or bypass the queue. `Lead` 按需确定人数，上限硬性 5 人；超出排队，不能默认固定 2 人。
2. Give every task an explicit dispatch brief (goal, dependency, exclusive file/module owner, interface contract, acceptance commands/criteria, out of scope, branch). Keep a dependency graph, critical path, decision log and restartable task ledger; only Lead changes canonical assignment/state. Avoid concurrent writes to shared files or `TASKS.md`.
3. Engineers isolate work in per-task branches/worktrees, write tests and self-test, commit/push and report exact SHA/commands/results/timestamps. Reviewer independently tests the **exact SHA**, checks specification compliance then code quality, and runs applicable functional **and UI/UX** acceptance. Reviewer issues evidence-backed `APPROVED`, `REJECTED` or `BLOCKED`; never silently approve missing mandatory environments.
4. For UI-affecting changes, Reviewer produces an independent, reproducible UI/UX review with screenshots/video or comparable actual execution evidence, critical-path and viewport/DPI/device matrix, severity and **score out of 100**. Merge gate: **at least 85**, release gate: **at least 90**, **zero P0/P1 blocking defects**, and all mandatory checks passing. Scores cannot override a hard failure. Non-UI changes follow the documented applicability rule.
5. Lead alone authorizes integration within permission limits; compare branch HEAD to reviewer-approved SHA, and rerun mandatory target-branch tests after integration before marking `DONE`. Preserve unmerged data/worktrees and respect protected branches. If Agent tools or required test devices are missing, report `BLOCKED` and ask for a permitted execution path.

Use the language-specific reference as the detailed procedure; do not assume this short router is sufficient. 禁止用短入口替代完整流程，禁止虚构 Agent、时间、设备测试或批准结果。
