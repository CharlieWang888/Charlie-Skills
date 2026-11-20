# Required AGENTS.md repository binding / 仓库强绑定规则（V2.1）

This file is normative for every invocation of the `multi-agent-development` skill. 本文件是该 Skill 每次启用时必须执行的约束，不是可选建议。

## Installation gate / 启动前门禁

1. **Before assigning an engineer, starting implementation or changing task state**, identify the Git repository root and read its existing root `AGENTS.md` (and any applicable nested rules). 在派单、开发或改变任务状态前，定位 Git 根目录并阅读现有规则。
2. If root `AGENTS.md` is absent, create it. If present, preserve all unrelated contents and append the exact block below. If the marked block is already present, update only that block in place; never duplicate it, remove another team's rules, or change unrelated sections. 根目录必须使用大小写正确的 `AGENTS.md`，重复调用必须幂等。
3. Persist the binding in the repository and commit/push it at the earliest authorized opportunity, before ordinary feature dispatch. Respect protected branches and existing review rules; do not force-push or bypass approval. 绑定必须写入仓库，而不只留在聊天或任务提示词中。
4. If the binding cannot be safely written or integrated because of permissions, conflicting higher-priority instructions or a protected workflow, report `BLOCKED` and seek user direction. Do not claim that the repository has been bound, silently revert to a single agent, or fabricate a team. 遇阻塞如实暂停，不可声称已绑定。
5. Keep the binding across future sessions, new agents and skill upgrades. On every invocation, update old managed V1.x blocks in place to the latest approved contract; never append a second managed block. Remove or weaken the binding only with explicit user authorization. This rule applies each time the skill is invoked, not just the initial installation. 后续所有开发会话均受其约束。

## Exact managed block / 原样写入 AGENTS.md 的约束块

The lines between the two markers below (inclusive) are the managed block. Preserve the rest of `AGENTS.md` unchanged.

<!-- multi-agent-development:binding:start -->
## Mandatory Multi-Agent Development / 强制多 Agent 协同

- **Skill binding / Skill 强绑定：** This repository uses [multi-agent-development](https://github.com/CharlieWang888/Charlie-Skills/tree/main/multi-agent-development) for all subsequent software-development tasks. Every Lead, Engineer and Reviewer must read this `AGENTS.md` and follow the skill workflow at the beginning of each development session. 不得因后续请求未重复提及 Skill 就静默退回单 Agent 工作流；仅用户明确授权才可解除绑定。
- **Team and review / 协同与验收：** Lead owns decomposition, dynamic Engineer headcount, dispatch, canonical task status and authorized integration. Lead chooses 0–5 Engineers based on ready independent tasks, file ownership, review capacity and actual runtime slots; **five is the hard maximum, never a staffing target**. There is one independent Reviewer; every Engineer has isolated tasks/branches/worktrees. Reviewer validates specification, code quality, and independently runs required functional plus applicable UI/UX gates on the exact SHA. If subagents are unavailable, mark collaboration `BLOCKED`, explain the limitation and seek authorization for an alternate mode; never invent agents, tests or review.
- **Queue and ownership / 排队与文件所有权：** Any additional ready work beyond the five-Engineer cap or other real capacity enters canonical `QUEUED` with priority/reason; **never dispatch a sixth Engineer**. Allow at most five active unmerged task branches. Lead alone changes formal task state and assigns one writer per shared file/interface, or serializes dependent work. Keep a dependency/critical-path view, standard task brief (goal, ownership, API contract, exact acceptance, out-of-scope) and durable decision/resume ledger in `TASKS.md` or its equivalent.
- **Independent UI/UX gate / UI 与 UX 独立验收：** For UI-affecting work or release, read [the UI/UX acceptance contract](https://github.com/CharlieWang888/Charlie-Skills/blob/main/multi-agent-development/references/ui-ux-acceptance.md) and have Reviewer actually run supported critical user journeys, viewport/DPI/device/input/accessibility checks and capture evidence. UI-changing tasks require a scored 100-point review: **merge ≥85, release ≥90, zero P0/P1 blockers, all mandatory tests/platform checks passing**. Scores never override hard failures. Unavailable mandatory target UI environment means `BLOCKED`, not an imaginary PASS; Engineer screenshots do not replace independent checks. Record the review and link it from canonical tasks. Non-UI changes use the documented `SMOKE`/`NA` applicability rule.
- **Tokyo timezone for every timestamp / 全部统一东京时区：** Every Lead/Engineer/Reviewer `START`/`END`, measurable subtask, UI/UX review, `TASKS.md` timestamp and final report **MUST use `Asia/Tokyo` (JST, UTC+09:00)**, even if agents run on UTC or other timezone hosts. Read the real event instant and convert both date and clock time into JST. Format `YYYY-MM-DD HH:MM:SS +09:00 zone=Asia/Tokyo`; never merely relabel a local/UTC wall time as JST.
- **Start clock / 启动计时：** At every session or resumed round, Lead immediately prints the real Tokyo-converted start timestamp and starts the round timer. Each Engineer and Reviewer likewise logs their own real start instant converted to Tokyo time when taking an assignment.
- **End clock / 结束计时：** At every completed, paused or blocked round, Lead must report the real end instant **in Tokyo time**, round elapsed (`HH:MM:SS`) and overall project/task elapsed from first start. Each Engineer/Reviewer must report their JST end timestamps and elapsed durations. Each completed measurable subtask must show Tokyo start/end and elapsed. 不得漏掉耗时、伪造时间或混用其他时区。
- **Persist timing / 持久化时间：** In `TASKS.md` or its canonical equivalent, save **all newly recorded timestamps in `Asia/Tokyo` +09:00**: scope original start, each round start/end, each Agent/subtask start/end and final completion; record elapsed durations separately. For legacy first starts in another explicit timezone, keep the original instant/provenance and store a converted JST presentation value; never reset or shift the real scope start. Distinguish wall-clock overall vs measured active time; never sum overlapping Agent durations as total elapsed. Missing measurements use `NOT MEASURED` plus reason.
- **Evidence / 真实性：** Derive real instants from an available clock, convert to JST with timezone-aware conversion, and calculate elapsed from actual instants (prefer a monotonic clock for continuous work). UTC/Los Angeles/Beijing host wall times cannot be copied verbatim into a Tokyo timestamp. Report interruptions, pauses and missing values; never infer successful completion or background execution.
<!-- multi-agent-development:binding:end -->

## Time reporting contract / 计时报表协议

At the start of every Lead round, show `[START] role=Lead time=YYYY-MM-DD HH:MM:SS +09:00 zone=Asia/Tokyo`; do the same for every dispatched Agent at its **own actual start instant**. All `time=`, `start=`, `end=`, original-start, completion and review timestamps must be formatted in JST. Do not work first and backfill a fictional start. 东京时间比 UTC 快 9 小时，需换算日期和时钟，而非只替换偏移。

At each Engineer, Reviewer or completed subtask handoff, show `[END] role=Engineer task=T-01 time=YYYY-MM-DD HH:MM:SS +09:00 zone=Asia/Tokyo elapsed=HH:MM:SS` or `[SUBTASK] id=T-01 start=<JST timestamp> end=<JST timestamp> elapsed=HH:MM:SS`. Persist actual Tokyo-formatted times in the task tracker.

At every Lead stop or handoff, show `[END] role=Lead time=YYYY-MM-DD HH:MM:SS +09:00 zone=Asia/Tokyo round_elapsed=HH:MM:SS overall_elapsed=...`; include the JST first-start and last-finish timestamps and full elapsed duration when the scope finishes. `overall_elapsed` is wall-clock time since the first recorded start (including waits and between-session gaps); measured active time, if available, must be a separate number, not a sum of overlapping agents' hours. Paused work remains `IN_PROGRESS` or `BLOCKED`; do not mislabel it `DONE`.

If a session ends unexpectedly and an end timestamp cannot be observed, leave it unknown rather than fabricating it; the next Lead records the restart time and states the measurement gap.

## Common shortcuts that are not allowed / 禁止的借口

| Shortcut / 借口 | Required behavior / 必须执行 |
|---|---|
| "The user only asked for a tiny change." / 只是小改动 | Binding and timing still apply when this skill is invoked. / 仍需绑定与计时 |
| "We already applied the skill in another chat." / 之前用过 | Read/verify `AGENTS.md` every round; do not duplicate the marked block. / 每轮校验 |
| "We can add AGENTS.md after coding." / 先开发后补 | The repository binding is a pre-dispatch gate. / 派单前门禁 |
| "The agents are parallel, so add their hours for total time." / 并行耗时相加 | Distinguish end-to-end wall time from per-agent effort. / 区分总历时与人工工时 |
| "No clock/tool/review agent available, but probably completed." / 工具不可用 | Report missing evidence and `BLOCKED`; ask the user before changing mode. / 如实阻塞 |
| "Five Engineers are allowed, so spawn all five." / 上限五名就全派 | Lead selects actual need; five is a ceiling, not a target. / 按需派单 |
| "The deadline needs a sixth Engineer." / 紧急任务开第六名 | Never exceed five; put excess ready work in durable `QUEUED`. / 超额排队 |
| "The tests pass and the screenshot looks good." / 测试绿、截图漂亮 | Reviewer must independently execute UI/UX when applicable; P0/P1 blocks regardless of score. / 实测硬门禁 |
| "Windows/iOS GUI could not run, so skip it." / 没有目标平台 | Mandatory UI checks that cannot run mean `BLOCKED`, not `APPROVED`. / 无法实测则阻塞 |
| "The Agent runs on UTC, so log UTC." / 机器是 UTC | Always convert real instants to `Asia/Tokyo` (+09:00) for every role, subtask, review and canonical report. / 全部换算东京时间 |
| "Just change +00:00 to +09:00." / 只改时区标记 | Recalculate the calendar day and clock hour; never relabel an instant. / 必须真实换算 |
| "Historical first-start used another timezone, reset it." / 历史记录重置 | Preserve original instant/provenance, add JST view, keep total wall time unchanged. / 保留历史起点 |
