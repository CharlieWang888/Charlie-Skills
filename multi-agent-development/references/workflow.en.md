# Autonomous Multi-Agent Software Development Workflow (V1.1)

**Core principle: one lead orchestrates, at most two engineers implement in parallel, and one independent reviewer verifies. Persist task state, require real test evidence, and clean up branches safely.**

Apply this skill to ongoing work in an existing Git repository. Respect the user's authorization, the repository's existing workflow, available tools, and platform permissions. A chat session is not an indefinitely running background service.

## 1. Roles and authority

| Role | Count | Responsibilities | Must not |
|---|---:|---|---|
| Lead / project manager (main conversation) | 1 | Inspect the repository, plan and assign tasks, update canonical task state, coordinate authorized merges and cleanup, report progress | Implement product code; bypass approvals or protected branches |
| Engineer | Up to 2 | Implement with TDD, test, fix, commit and push in isolated branches/worktrees | Self-approve or mark a task DONE; assign tasks or merge protected branches |
| Reviewer | 1 | Independently check code, run verification commands, issue a structured verdict | Edit product code, relax quality gates, dispatch work or merge |

The Lead is the **only dispatcher**. Engineers and the reviewer report to the Lead; the reviewer does not assign fixes directly. If subagents cannot be created, state that limitation and ask how to proceed. Never invent agent work or test results.

## 2. Start from a single source of truth

**Mandatory prerequisite:** The Lead first prints the actual start timestamp with timezone and starts the round timer, then reads the full [repository binding and time tracking contract](repository-binding.md). Before any engineering dispatch, product-code edit or task-state transition, check root `AGENTS.md`; create it if missing, or update only the marked block while preserving all unrelated rules. Commit/push within authorized branch policies. If the binding cannot be safely persisted, mark `BLOCKED` and ask the user; do not silently proceed. Check it again on every later skill invocation without duplicating the block.

1. Fetch and inspect the latest remote repository state, default branch, outstanding work and test baseline.
2. Read the existing `AGENTS.md`, `PRD.md`, roadmap and task tracker; reuse equivalent files if named differently. Where missing, create concise versions from confirmed repository conventions and user requirements; clarify missing scope or acceptance requirements rather than inventing them.
3. Have the Lead maintain `TASKS.md` or the existing equivalent. **Only the Lead changes canonical task states and assignees**; other roles submit structured reports. Commit/push significant state transitions to the agreed shared branch so remote state is resumable; never race multiple branch copies of the task tracker.
4. Record for each task: unique ID, objective, assignee, priority, dependencies, allowed modules/files, acceptance criteria and commands, status, branch, commit SHA and review evidence.
5. Reread task instructions and relevant repository rules before every assignment. Never assume a new subagent inherits an earlier conversation.

### Mandatory timing and durable evidence for every agent

- **Start of each round:** Lead, Engineer and Reviewer each print `[START] role=... time=YYYY-MM-DD HH:MM:SS ±timezone` at their real start; the Lead immediately starts the round timer.
- **End, pause or blocker:** Each agent prints the actual finish time and round elapsed duration `HH:MM:SS`; the Lead also reports overall elapsed time. For each completed measurable subtask, record its own start, finish and elapsed duration.
- **Total task clock:** Persist the first-ever scope start in `TASKS.md` or the canonical tracker and never reset it on resumed rounds. At final completion, show first start, final finish and overall wall-clock duration, including waits and gaps. If measuring active work separately, label it explicitly; **do not add parallel agent durations and present the sum as end-to-end elapsed time**.
- **Accuracy:** Use a real clock and explicit timezone; prefer a monotonic timer for a continuous execution segment. Mark unknown values `NOT MEASURED` with a reason; never backfill fabricated values or imply a chat session runs indefinitely in the background. The exact binding text and reporting format are in the [common template](repository-binding.md).

### Task states

| State | Meaning |
|---|---|
| `TODO` | Defined and waiting for assignment |
| `IN_PROGRESS` | Assigned for implementation or rework |
| `IN_REVIEW` | Engineer pushed the change and supplied self-test evidence |
| `REJECTED` | Independent review failed; Lead must dispatch the fix |
| `APPROVED` | Reviewer confirmed the agreed acceptance gates |
| `BLOCKED` | Permissions, environment, dependencies or repeated failures prevent progress |
| `DONE` | Authorized merge is complete and required target-branch integration tests pass |

Engineer completion, reviewer approval and merge success are **not** by themselves equivalent to `DONE`.

## 3. Event-driven orchestration loop

1. Read the latest task tracker, select high-priority tasks with satisfied dependencies, and assign up to two engineers strictly non-overlapping modules/files. If this is impossible, serialize the tasks or explicitly assign file ownership first.
2. Have each engineer use a separate worktree and `feat/task-<id>` branch, apply applicable test-driven development practices, and add necessary, accurate English code comments.
3. After implementation and self-testing, require a commit/push and a report containing the diff summary, branch, SHA, exact commands, exit codes, test counts, and that agent's and subtask's actual start/end/elapsed times; move the task to `IN_REVIEW`.
4. Have the reviewer use an isolated checkout of that exact SHA and run the applicable gates. Test-generated temporary outputs are allowed, but the reviewer must not edit reviewed product code. Accept only an evidence-backed `APPROVED`, `REJECTED` or `BLOCKED` verdict.
5. Dispatch any fix, perform authorized merges and post-merge tests, update task state, then select the next ready task.

React to agent completion events first, with periodic remote/task reconciliation as a safety net. **Do not run a permanently polling subagent.** Engineers may become available after pushing a task, but by default allow no more than two active, unmerged task branches across the project. Clear review/integration backlogs before expanding concurrent work.

## 4. Independent deterministic quality gates

Define mandatory acceptance commands **before dispatch**, then apply the relevant checks for the repository and target platforms: type checking, lint/static analysis, unit tests, integration/regression tests, full build, and necessary GUI/CLI/E2E or platform-specific checks.

- The reviewer must **run tools independently**, recording exact commands, environment, SHA, exit codes and passed/failed/skipped counts.
- Any failing required check (nonzero exit code) produces `REJECTED`. If a mandatory check cannot execute because of permissions or environment, use `BLOCKED`, never “all green.”
- Only after the mechanical gates pass, review functional logic, architecture, edge cases, requirement coverage and regression risk.
- Check that tests, assertions, fixtures or skips were not weakened to produce false passes.
- Never retroactively relax acceptance criteria, fabricate results or count skipped checks as passed.
- Mark unavailable platform tests as `NOT RUN` with risk stated explicitly; Linux-only checks cannot establish Windows/iOS device verification.

The review report must include review start/end times and elapsed duration, task ID, SHA, verdict, failing commands/tests and exit codes, reproduction steps, affected files, severity, expected outcome, environment, untested areas and proposed remediation. The reviewer does not edit product files.

## 5. Rejection, rework and blockers

1. Reviewer reports a structured verdict to the Lead; the Lead marks `REJECTED` and dispatches rework.
2. Prefer the original engineer to preserve context. If busy, the Lead schedules the fix; never allow two engineers to compete for one task.
3. Require self-tests, new commit/push and an independent re-review after every correction.
4. If the **same task is rejected more than twice in succession**, mark `BLOCKED`; the Lead must diagnose, split or reassign it and ask the user when a material decision is needed.
5. Pause honestly for missing repository permissions, dependencies, platforms or human approvals; never work around access controls.

## 6. Git branch lifecycle

- Follow the repository's existing default, integration and release branch policy. Use `dev` for integration if it already exists; **do not create a new `dev` or alter release conventions without authorization**.
- Use one short-lived `feat/task-<id>` branch per task; reuse it for all rework. Give each engineer a separate worktree.
- Commit and push after successful self-tests. Review an immutable SHA, and do not merge unapproved work.
- The Lead merges `APPROVED` changes only within granted authority. **Immediately before merging, verify that the branch HEAD still matches the reviewer-approved SHA**; if new commits exist, re-review the new SHA. Rerun every required target-branch check after integration; only then mark `DONE`.
- **Before deleting a temporary local/remote branch**, confirm the change has landed in the target branch, its required tests pass and the source branch has no unique unmerged commits. Before removing its worktree, also inspect staged, unstaged, untracked and ignored files; preserve and report any unique data, never force-delete it.
- Never automatically delete `main`, `dev`, `release/*`, explicitly retained research branches, or any branch holding unmerged work. Do not force-push, bypass protections or merge protected release branches without permission.
- Keep SHAs, PRs/MRs, task state and review records as durable history; periodically audit merged branches awaiting safe cleanup.

## 7. Completion and reporting

Declare the scoped work complete only if every task is `DONE`, no `REJECTED/BLOCKED` task remains, changes are pushed and merged as authorized, all mandatory integration checks pass, and the reviewer provides a final verdict. Otherwise report blockers and retain restartable project state.

Keep interim status updates short. The final Lead report must include round start/end timestamps and duration, first-ever task start and overall elapsed time, per-agent and completed-subtask timings, total/completed/remaining/blocked tasks, features and fixes, exact test commands and results, branches and commit SHAs, merge/cleanup status, independent review conclusions, remaining risks and user acceptance steps.

**Common failures to prevent:** trusting an engineer's “tests passed” claim instead of independent verification; sharing one writable worktree; holding state only in chat; deleting unmerged branches; reporting missing tools as PASS; or allowing reviewer-to-engineer dispatch outside the Lead. Stop the affected transition and correct it.
