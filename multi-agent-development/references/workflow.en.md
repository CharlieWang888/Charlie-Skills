# Autonomous Multi-Agent Software Development Workflow (V2.1)

**Core principle: Lead chooses the number of Engineers dynamically, with a hard maximum of five; excess ready tasks enter `QUEUED`. One independent Reviewer verifies specifications, actual code/test results, and applicable UI/UX quality. Keep resumable state, real evidence and safe integration.**

Apply this skill to ongoing work in an existing Git repository. Respect the user's authorization, the repository's existing workflow, available tools, and platform permissions. A chat session is not an indefinitely running background service.

## 1. Roles and authority

| Role | Count | Responsibilities | Must not |
|---|---:|---|---|
| Lead / project manager (main conversation) | 1 | Inspect the repository, plan and assign tasks, update canonical task state, coordinate authorized merges and cleanup, report progress | Implement product code; bypass approvals or protected branches |
| Engineer | 0–5, chosen by Lead; hard cap 5 | Implement with TDD, test, fix, commit and push in isolated branches/worktrees | Spawn a sixth Engineer; self-approve or mark DONE; assign tasks or merge protected branches |
| Reviewer | 1 | Independently check spec compliance, code quality, actually run tests and applicable UI/UX gates on an exact SHA; issue a structured verdict | Edit product code, relax test/UI gates, dispatch work or merge |

The Lead is the **only dispatcher** and selects 0–5 Engineers based on dependency-ready independent work, file ownership, review throughput, actual available slots and cost. **Five is a ceiling, never a required team size.** Put additional ready work into durable `QUEUED`, never start a sixth Engineer. Engineers and the Reviewer report to Lead; Reviewer does not assign fixes directly. For unusually high-risk work Reviewer may recommend a specialist check, scheduled only by Lead within user authorization and actual agent capacity, without replacing the single final independent Reviewer. If subagents cannot be created, mark `BLOCKED` and request direction. Never invent agent work or tests.

## 2. Start from a single source of truth

**Mandatory prerequisite:** The Lead immediately converts the real start instant to Tokyo `Asia/Tokyo` (JST, UTC+09:00), prints it and starts the round timer, then reads the full [repository binding and time tracking contract](repository-binding.md). Before any engineering dispatch, product-code edit or task-state transition, check root `AGENTS.md`; create it if missing, or update only the marked block while preserving all unrelated rules. Commit/push within authorized branch policies. If the binding cannot be safely persisted, mark `BLOCKED` and ask the user; do not silently proceed. Check it again on every later skill invocation without duplicating the block.

1. Fetch and inspect the latest remote repository state, default branch, outstanding work and test baseline.
2. Read the existing `AGENTS.md`, `PRD.md`, roadmap and task tracker; reuse equivalent files if named differently. Where missing, create concise versions from confirmed repository conventions and user requirements; clarify missing scope or acceptance requirements rather than inventing them.
3. Have the Lead maintain `TASKS.md` or the existing equivalent. **Only the Lead changes canonical task states and assignees**; other roles submit structured reports. Commit/push significant state transitions to the agreed shared branch so remote state is resumable; never race multiple branch copies of the task tracker.
4. Record for each task: ID, objective, priority, dependencies and `READY/WAITING` determination, assignee, **exclusive file/module ownership**, shared interface contract, acceptance commands/criteria, `UI_SCOPE`, explicit out-of-scope boundary, state, branch, SHA and linked review evidence. Keep a dependency/critical-path view, dispatch/decision log and precise resume pointer; persist queue reasons.
5. Reread task instructions and relevant repository rules before every assignment. Never assume a new subagent inherits an earlier conversation.

### Mandatory timing and durable evidence for every agent

- **Mandatory timezone for every timestamp:** Lead, Engineer, Reviewer, measurable subtask, UI/UX review, task ledger and final report **must all use `Asia/Tokyo` (JST, UTC+09:00)** regardless of the host/Agent's local timezone. Obtain the real event instant from an available clock and convert the calendar date/time, not merely relabel a UTC/local timestamp with `+09:00`.
- **Start of each round:** Each role prints `[START] role=... time=YYYY-MM-DD HH:MM:SS +09:00 zone=Asia/Tokyo` at its actual start; Lead immediately starts the round timer.
- **End, pause or blocker:** Each Agent prints the real finish instant converted to Tokyo time and its round elapsed duration `HH:MM:SS`; Lead also reports overall elapsed. For each completed measurable subtask, record JST start, finish and elapsed. Elapsed durations do not change with timezone.
- **Total task clock:** Persist the first-ever scope start in JST in `TASKS.md` or the canonical tracker and never reset it on resumed rounds. For a historical first-start value with an explicit UTC/other offset, **preserve its original instant and provenance and add a converted JST display value**; never shift the task's true starting instant. At completion, show Tokyo first-start/final-finish values and overall wall-clock duration including waits/gaps. Label active time separately; **never add parallel Agent durations and present the sum as end-to-end elapsed time**.
- **Accuracy:** Read real event instants from an available clock and convert them to `Asia/Tokyo`; subtract absolute instants for cross-zone elapsed time and prefer a monotonic timer within a continuous segment. Mark unknowns `NOT MEASURED` with a reason. Never backfill fabricated values, label another locale's wall time as JST without conversion, or imply background work after the chat ends. The exact binding/report format is in the [common template](repository-binding.md).

### Task states

| State | Meaning |
|---|---|
| `TODO` | Defined but not dependency-ready, or not yet placed among ready candidates |
| `QUEUED` | Dependency-ready but awaiting Engineer/branch/Reviewer capacity or scheduling priority; preserve queue reason and priority |
| `IN_PROGRESS` | Assigned for implementation or rework |
| `IN_REVIEW` | Engineer pushed the change and supplied self-test evidence |
| `REJECTED` | Independent review failed; Lead must dispatch the fix |
| `APPROVED` | Reviewer confirmed the agreed acceptance gates |
| `BLOCKED` | Permissions, environment, dependencies or repeated failures prevent progress |
| `DONE` | Authorized merge is complete and required target-branch integration tests pass |

Engineer completion, reviewer approval and merge success are **not** by themselves equivalent to `DONE`.

## 3. Event-driven orchestration loop

1. Read the current dependency graph/critical path and select highest-priority ready tasks with independent file ownership. Lead explicitly chooses this round's 0–5 Engineers; active work is limited by actual agent slots, **no more than five active unmerged task branches**, and Reviewer throughput. Move additional ready work to `QUEUED` with a reason and priority; reconsider when capacity becomes available. Never spawn a sixth Engineer.
2. Send the standard dispatch contract (below) first. Have each Engineer use a separate worktree and `feat/task-<id>` branch, apply applicable TDD and repository conventions, and add necessary, accurate English code comments. Assign a single writer for any shared file/interface or serialize otherwise.
3. After implementation and self-testing, require a commit/push and a report containing the diff summary, branch, SHA, exact commands, exit codes, test counts, and that agent's and subtask's actual start/end/elapsed times; move the task to `IN_REVIEW`.
4. Reviewer checks out the exact SHA in isolation, **first tests specification/acceptance compliance, then independently reviews code quality, runs verification commands and applicable UI/UX acceptance**. Test-generated temporary outputs are allowed, but no product-code edits. Do not trust Engineers' claimed greens or screenshots; accept only evidence-backed `APPROVED`, `REJECTED` or `BLOCKED`. Lead may request spec corrections before the full quality review but cannot skip independent execution.
5. Dispatch any fix, perform authorized merges and post-merge tests, update task state, then select the next ready task.

React to Agent completion events first; periodically reconcile remote/task state as a safety net. **Do not run a permanently polling subagent.** A task in `IN_PROGRESS/IN_REVIEW/REJECTED/APPROVED` occupies one active unmerged branch slot until integration; the project has a **hard cap of five active unmerged task branches**. An idle Engineer does not automatically free branch capacity. Prioritize clearing review/integration backlog before dispatching more `QUEUED` work. Use task-specific direct messages; broadcast only shared-interface changes, cross-team blockers and milestones.

### Mandatory dispatch contract, dependency and resumption ledger

Before assigning work, send a concise executable brief with these fields. Do not send the entire PRD indiscriminately or presume that an Agent remembers a past chat:

```text
Task ID / priority / dependencies / owner / branch
Goal and observable deliverable / requirements reference
Exclusive editable files and modules / shared files' single writer
Interface/API contract and integration assumptions
Acceptance: exact commands, expected result, platform, UI_SCOPE, UI/UX matrix
Out of scope / do-not-change / required evidence
Handoff: commit SHA, test exit codes/counts, findings, timestamps in Asia/Tokyo (+09:00)
```

Lead keeps the dependency DAG, critical path, file ownership table, `TODO → QUEUED → IN_PROGRESS → IN_REVIEW → APPROVED → DONE` transitions (including `REJECTED`/`BLOCKED` detours), queue priorities and reasons, reviewed SHAs, unmerged branch inventory, decisions/blockers, and exact next action for resumption in canonical `TASKS.md` or its equivalent. Dependency-unready tasks remain `TODO`. Give a shared interface/file exactly one Engineer owner or serialize instead of betting on two writable worktrees merging cleanly.

Lead may route tasks to supported models according to complexity, cost and runtime capability, **only using models and parameters actually advertised by the current tools**. Do not copy another platform's proprietary TeamCreate/TeamDelete commands, evade existing permissions or make paid CI/GitHub Actions a new mandatory substitute for independently executed local tests.

## 4. Independent deterministic quality gates

Define mandatory commands, platforms and UI/UX scenarios **before dispatch**, then run the relevant checks: type checking, lint/static analysis, unit tests, integration/regression tests, full build, and applicable GUI/CLI/E2E, accessibility or platform-specific tests. **For every UI/interaction/layout/accessibility/localization change or release, first read and enforce the complete [independent UI/UX acceptance contract](ui-ux-acceptance.md).**

- The reviewer must **run tools independently**, recording exact commands, environment, SHA, exit codes and passed/failed/skipped counts.
- Any failing required check (nonzero exit code) produces `REJECTED`. If a mandatory check cannot execute because of permissions or environment, use `BLOCKED`, never “all green.”
- Conduct two independent review passes: **specification/acceptance compliance** and **implementation quality** (logic, architecture, edge cases, regressions and applicable UI/UX). Neither pass can be replaced by an Engineer's self-report.
- Check that tests, assertions, fixtures or skips were not weakened to produce false passes.
- Never retroactively relax acceptance criteria, fabricate results or count skipped checks as passed.
- For `UI_SCOPE=FULL`, Reviewer actually exercises critical journeys on target platforms, inspecting layout/DPI/text scaling, interactions, required keyboard/touch input, accessibility, themes, long localizations and error states. Publish an independent UI/UX report with per-dimension scores plus screenshots, video or automation logs. **Merge requires ≥85/100; release requires ≥90/100; neither permits P0/P1 blocking defects.** A score cannot erase a failed hard gate. `SMOKE` gets independent UI smoke, and `NA` requires rationale with score `NOT APPLICABLE`. Read the [UI/UX contract](ui-ux-acceptance.md) for evidence matrix and weights.
- Mark unavailable **mandatory** target-platform checks `NOT RUN` plus risk and verdict `BLOCKED`; Linux-only tests cannot establish Windows/iOS native acceptance. A proven failed required check yields `REJECTED` rather than being hidden by other passes.

Use finding severity `P0 Critical / P1 High / P2 Medium / P3 Low`; `P0/P1` block approval. Reports include review start/end timestamps in Asia/Tokyo (+09:00) and elapsed, task ID and exact SHA, spec-compliance verdict, independent commands/exit codes/counts, reproduction, affected files, severity, expected vs actual, environment, untested areas and remediation. For `FULL` UI changes add platform evidence matrix, five weighted dimensions and total score, merge/release verdicts. Reviewer submits evidence to Lead; **Lead persists `reviews/<task-id>-ui-ux.md` or its existing equivalent and links it from canonical `TASKS.md`** so reviewers never race the tracker. Reviewer never edits product files.

## 5. Rejection, rework and blockers

1. Reviewer reports a structured verdict to the Lead; the Lead marks `REJECTED` and dispatches rework.
2. Prefer the original engineer to preserve context. If busy, the Lead schedules the fix; never allow two engineers to compete for one task.
3. Require self-tests, new commit/push and an independent re-review after every correction.
4. If the **same task is rejected more than twice in succession**, mark `BLOCKED`; the Lead must diagnose, split or reassign it and ask the user when a material decision is needed.
5. Pause honestly for missing repository permissions, dependencies, platforms or human approvals; never work around access controls.

## 6. Git branch lifecycle

- Follow the repository's existing default, integration and release branch policy. Use `dev` for integration if it already exists; **do not create a new `dev` or alter release conventions without authorization**.
- Use one short-lived `feat/task-<id>` branch per task; reuse it for all rework. Give **each Engineer a separate worktree, with no more than five active unmerged task branches**.
- Commit and push after successful self-tests. Review an immutable SHA, and do not merge unapproved work.
- The Lead merges `APPROVED` changes only within granted authority. **Immediately before merging, verify that the branch HEAD still matches the reviewer-approved SHA**; if new commits exist, re-review the new SHA. Rerun every required target-branch check after integration; only then mark `DONE`.
- **Before deleting a temporary local/remote branch**, confirm the change has landed in the target branch, its required tests pass and the source branch has no unique unmerged commits. Before removing its worktree, also inspect staged, unstaged, untracked and ignored files; preserve and report any unique data, never force-delete it.
- Never automatically delete `main`, `dev`, `release/*`, explicitly retained research branches, or any branch holding unmerged work. Do not force-push, bypass protections or merge protected release branches without permission.
- Keep SHAs, PRs/MRs, task state and review records as durable history; periodically audit merged branches awaiting safe cleanup.

## 7. Completion and reporting

Declare the scoped work complete only if every task is `DONE`, none remain `TODO/QUEUED/IN_PROGRESS/IN_REVIEW/REJECTED/BLOCKED`, changes are pushed and merged as authorized, mandatory integration and applicable UI/UX merge/release gates pass, and Reviewer provides a final verdict. Otherwise report blockers and retain restartable project state.

Keep interim status updates short. The final Lead report must include all round start/end and first-ever task start timestamps in `Asia/Tokyo` (+09:00), their durations and overall elapsed time, per-agent and completed-subtask timings, total/completed/`QUEUED`/blocked tasks, selected Engineer headcount and active branch count, critical path and blocker decisions, features and fixes, independently executed commands/results, UI/UX matrix/score/blockers, branches and commit SHAs, merge/cleanup status, independent review conclusions, remaining risks and user acceptance steps.

**Common failures to prevent:** still fixing the team at two Engineers, treating five as a quota, dispatching a sixth without queuing, letting multiple Engineers write the same shared file, reviewing screenshots without actual UI execution, using an 85 score to excuse a P1 defect, marking unavailable Windows/iOS checks PASS, retaining state only in chat, deleting unmerged branches, or allowing Reviewer-to-Engineer dispatch. Stop the affected transition and correct it.
