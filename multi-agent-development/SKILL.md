---
name: multi-agent-development
description: Use when coordinating software development with multiple agents, independent code and UI/UX review, persistent task tracking, Git branch isolation, implement-test-review-merge cycles, AGENTS.md repository binding, or per-agent/subtask/total elapsed-time reporting. 适用于强绑定仓库多任务协同、按需调度工程师、UI/UX 验收及真实计时。
---

# Multi-Agent Development / 多 Agent 自主软件开发（V2.3）

One Skill entry and one state machine, with Chinese and English workflow references. Language affects presentation, never scheduling, quality gates, or permissions. 单一入口与状态机，中英文规则同等有效。

## Non-negotiable repository gate / 仓库强绑定门禁

**Every invocation, before product-code changes, task-state transitions or engineering dispatch:**

1. Capture the Lead round's real start instant immediately; read [repository-binding.md](references/repository-binding.md) **completely** and inspect pre-existing root `AGENTS.md` to select the effective repository timezone before formatting the `[START]` output. Print every event instant using the selected IANA zone/UTC offset; `Asia/Tokyo` (JST, UTC+09:00) is the default, not an override of an explicit non-managed project rule.
2. Read the target repository root `AGENTS.md` and applicable nested instructions. Create or update **only** the uniquely marked managed block from the binding reference; preserve unrelated instructions. Persist and commit/push under existing authorization and branch policy. If this cannot safely be persisted, mark `BLOCKED` and request direction; never silently bypass the binding.
3. Record original first start, each round's start/end/elapsed time, every Agent's and measurable subtask's timing, UI/UX review time, and total wall-clock elapsed in canonical `TASKS.md` or equivalent **and in the visible chat contract below**. **Use the effective repository timezone consistently in all new timestamp fields, task ledgers and user-facing reports**; convert offset-aware instants for display without changing the true first-start or provenance. Never add parallel Agent durations as total elapsed. Mark unknowns `NOT MEASURED` with reasons.

**Timezone precedence / 时区优先级（强制）：** Before dispatch, read the existing root `AGENTS.md`. If a pre-existing **non-managed** instruction expressly mandates a valid IANA time zone and UTC offset, that repository rule determines the effective zone for every Agent, subtask, `TASKS.md` entry and report. Otherwise use `Asia/Tokyo` (JST, UTC+09:00). Convert actual event instants to the selected zone; keep the original first-start instant and provenance. Never silently edit/override a non-managed rule or mix zones within one repository. If the rule is ambiguous, invalid or contradictory, mark `BLOCKED` and ask the user. **Existing Knife-Zip rule `Asia/Shanghai` (UTC+08:00) is an authorized example.**

**每次调用都必须重检项目根目录 `AGENTS.md` 的强绑定，先读取真实事件时间与仓库非托管时区规则，再换算为该仓库统一时区并计时；无明确规则时默认东京 `Asia/Tokyo`（UTC+09:00）。所有 Agent/子任务/审查/最终报告使用同一有效时区，跨会话总历时不重置。**

## Visible chat timing contract / 聊天强制可见计时

**A tracker entry or collapsible commentary is not the user-facing handoff.** This V2.3 contract has two separate required displays:

1. **CHAT START dispatch matrix / 聊天 START 派工矩阵.** In visible chat at each Lead round start, show the observed `[START] role=Lead` instant, `selected_engineers=N` (integer 0–5) and why that number fits independent READY work, actual slots, ownership and Reviewer capacity. Include a compact matrix with each actionable task's `READY / QUEUED / BLOCKED` status, concrete reason, owner or unassigned, branch and observed Agent start or `NOT STARTED`. Show a zero-Engineer row and reason when N=0. Record actual Engineer/Reviewer `[START]` and `[END]` at their own event instants and relay each handoff visibly; no fabricated clocks or filler Agents.
2. **VISIBLE TERMINAL FINAL / 必须出现在 terminal final.** Every Lead round's **terminal final** response (even a pause or blocker, not only DONE) contains a complete **per-role timing table**: Lead, each actually dispatched Engineer, and Reviewer; each row identifies task/state, start, end, elapsed and evidence or reason. For an unassigned/pending role show `NOT STARTED`; for missing observed time use `NOT MEASURED` **and the reason**, never invent a timestamp. Report Lead `round_elapsed` and `first_scope_elapsed` as distinct wall-clock intervals with their real start/end instants, including waits. A short commentary update, `TASKS.md` link or intermediate partial final **never substitutes** for the terminal final table.

The same contract, bilingual tables and an executable actual-chat acceptance gate are in [repository-binding.md](references/repository-binding.md). **V2.3 pass condition: the user can read all roles, decisions and elapsed times in the final visible reply without opening a tracker.** 动态 0–5 是资源判断，不是为了展示并行而派工。

## Select full workflow / 选择完整工作流

| User language / 用户语言 | Required reference / 必读 |
|---|---|
| 中文 | [workflow.zh-CN.md](references/workflow.zh-CN.md) |
| English or other | [workflow.en.md](references/workflow.en.md) |
| Explicit bilingual comparison / 双语对照 | Read both / 两份都读 |

Also read [UI/UX acceptance contract](references/ui-ux-acceptance.md) completely for any UI-affecting task or release readiness check. 对 UI 相关任务和发布验收，完整阅读 UI/UX 规范。

## Mandatory orchestration / 强制协同规则

1. **Lead = the main conversation; up to five concurrently assigned Engineers; one independent Reviewer.** The Lead determines the number of Engineers from independent ready tasks, file ownership, review capacity and actual runtime slots. **Five is a hard cap, not a target.** Ready tasks beyond available capacity go into durable `QUEUED` **with reason in the visible START dispatch matrix**; never spawn a sixth Engineer or bypass the queue. `Lead` 按需确定人数，上限硬性 5 人；超出排队，不能默认固定 2 人。
2. Give every task an explicit dispatch brief (goal, dependency, exclusive file/module owner, interface contract, acceptance commands/criteria, out of scope, branch). Keep a dependency graph, critical path, decision log and restartable task ledger; only Lead changes canonical assignment/state. Avoid concurrent writes to shared files or `TASKS.md`.
3. Engineers isolate work in per-task branches/worktrees, write tests and self-test, commit/push and report exact SHA/commands/results/timestamps. Reviewer independently tests the **exact SHA**, checks specification compliance then code quality, and runs applicable functional **and UI/UX** acceptance. Reviewer issues evidence-backed `APPROVED`, `REJECTED` or `BLOCKED`; never silently approve missing mandatory environments.
4. For UI-affecting changes, Reviewer produces an independent, reproducible UI/UX review with screenshots/video or comparable actual execution evidence, critical-path and viewport/DPI/device matrix, severity and **score out of 100**. Merge gate: **at least 85**, release gate: **at least 90**, **zero P0/P1 blocking defects**, and all mandatory checks passing. Scores cannot override a hard failure. Non-UI changes follow the documented applicability rule.
5. Lead alone authorizes integration within permission limits; compare branch HEAD to reviewer-approved SHA, and rerun mandatory target-branch tests after integration before marking `DONE`. Preserve unmerged data/worktrees and respect protected branches. If Agent tools or required test devices are missing, report `BLOCKED` and ask for a permitted execution path.

Use the language-specific reference as the detailed procedure; do not assume this short router is sufficient. 禁止用短入口替代完整流程，禁止虚构 Agent、时间、设备测试或批准结果。
