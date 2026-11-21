# Required AGENTS.md repository binding / 仓库强绑定规则（V2.3）

This file is normative for every invocation of the `multi-agent-development` skill. 本文件是该 Skill 每次启用时必须执行的约束，不是可选建议。

## Installation gate / 启动前门禁

1. **Before assigning an engineer, starting implementation or changing task state**, identify the Git repository root and read its existing root `AGENTS.md` (and any applicable nested rules). 在派单、开发或改变任务状态前，定位 Git 根目录并阅读现有规则。
2. If root `AGENTS.md` is absent, create it. If present, preserve all unrelated contents and append the exact block below. If the marked block is already present, update only that block in place; never duplicate it, remove another team's rules, or change unrelated sections. 根目录必须使用大小写正确的 `AGENTS.md`，重复调用必须幂等。
3. Select the effective timezone before constructing the managed block: when a pre-existing non-managed root `AGENTS.md` rule clearly mandates an IANA zone and offset, that project rule wins (e.g. `Asia/Shanghai` UTC+08:00 for Knife-Zip with explicit user confirmation); otherwise default to `Asia/Tokyo` JST UTC+09:00. Treat conflicting/invalid/ambiguous existing rules as `BLOCKED` requiring user direction. Persist the binding in the repository and commit/push it at the earliest authorized opportunity, before ordinary feature dispatch. Respect protected branches and existing review rules; do not force-push or bypass approval. 绑定必须写入仓库，而不只留在聊天或任务提示词中。
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
- **Repository timezone precedence / 仓库时区优先：** All Lead/Engineer/Reviewer `START`/`END`, measurable subtask, UI/UX review, `TASKS.md` timestamp and final reports **MUST use one effective repository time zone**. If a pre-existing non-managed root `AGENTS.md` instruction explicitly requires an IANA zone and UTC offset, use that zone without changing that instruction; otherwise default to `Asia/Tokyo` (JST, UTC+09:00). For example, Knife-Zip's existing `Asia/Shanghai` UTC+08:00 remains authoritative by user approval. Convert actual instants, never merely relabel the time/offset. Ambiguous/conflicting project rules require `BLOCKED` and user clarification.
- **Start clock / 启动计时：** At every session or resumed round, Lead immediately captures the real start instant, identifies the effective repository timezone from `AGENTS.md`, prints its converted timestamp and starts the round timer. Each Engineer and Reviewer logs its own real start instant converted to the same zone when taking an assignment.
- **End clock / 结束计时：** At every completed, paused or blocked round, Lead must report the real end instant **in the effective repository timezone**, round elapsed (`HH:MM:SS`) and overall project/task elapsed from first start. Each Engineer/Reviewer and measurable subtask reports start/end in that same zone with its actual elapsed duration. 不得漏掉耗时、伪造时间或在仓库内混用时区。
- **Persist timing / 持久化时间：** In `TASKS.md` or its canonical equivalent, save **all newly recorded timestamps in the effective repository timezone**: scope original start, round start/end, Agent/subtask start/end and final completion; record elapsed durations separately. For legacy first starts in another explicit zone, keep the original instant/provenance and optionally add a converted display value; never reset or shift the real scope start. Distinguish wall-clock overall vs measured active time; never sum overlapping Agent durations. Missing measurements use `NOT MEASURED` plus reason.
- **Visible chat timing / 聊天可见计时：** At every Lead `[START]`, print a user-visible **CHAT START dispatch matrix / 聊天 START 派工矩阵** with dynamic `selected_engineers=N` (0–5) and the capacity/ownership reason, plus each actionable task's `READY / QUEUED / BLOCKED` status and concrete reason. Relays of actual Agent `[START]`/`[END]` happen at measured instants. Every round's **terminal final** must contain the full Lead/Engineer/Reviewer per-role timing table (or `NOT STARTED`/`NOT MEASURED` with reason) and both Lead `round_elapsed` and `first_scope_elapsed`. The user must not need to open `TASKS.md` or expand commentary to read times. This visible output is additional to durable tracker writes and never authorizes invented agent work. 每轮必须在用户可见最终答复里列出真实逐角色耗时，不能只记录在 TASKS 或折叠消息。
- **Evidence / 真实性：** Derive real instants from an available clock, convert to the effective repository timezone with timezone-aware conversion, and calculate elapsed from actual instants (prefer a monotonic clock for continuous work). Another host zone's wall time cannot be copied verbatim into the selected timezone. Report interruptions, pauses and missing values; never infer successful completion or background execution.
<!-- multi-agent-development:binding:end -->

## Time reporting contract / 计时报表协议

At the start of every Lead round, capture the real instant, select the effective repository timezone, then show `[START] role=Lead time=YYYY-MM-DD HH:MM:SS <offset> zone=<IANA-zone>`; do the same for every dispatched Agent at its **own actual start instant**. Use that zone consistently for `time=`, `start=`, `end=`, original-start, completion and review timestamps. Default example: `+09:00 zone=Asia/Tokyo`; if the repository mandates Shanghai: `+08:00 zone=Asia/Shanghai`. Do not backfill fictional times or simply change offset labels.

At each Engineer, Reviewer or completed subtask handoff, show `[END] role=Engineer task=T-01 time=YYYY-MM-DD HH:MM:SS <offset> zone=<IANA-zone> elapsed=HH:MM:SS` or `[SUBTASK] id=T-01 start=<zoned timestamp> end=<zoned timestamp> elapsed=HH:MM:SS`. Persist actual timestamps in the selected repository zone.

At every Lead stop or handoff, show `[END] role=Lead time=YYYY-MM-DD HH:MM:SS <offset> zone=<IANA-zone> round_elapsed=HH:MM:SS overall_elapsed=...`; include the first-start and last-finish instants in the repository zone and full elapsed duration when the scope finishes. `overall_elapsed` is wall-clock time since the first recorded start (including waits and between-session gaps); measured active time, if available, must be a separate number, not a sum of overlapping agents' hours. Paused work remains `IN_PROGRESS` or `BLOCKED`; do not mislabel it `DONE`.

If a session ends unexpectedly and an end timestamp cannot be observed, leave it unknown rather than fabricating it; the next Lead records the restart time and states the measurement gap.

## V2.3 user-visible CHAT START and terminal final slots / 用户可见回报格式

At **CHAT START**, print the observed Lead start first, then a compact **dispatch matrix / 派工矩阵** in visible chat. A sample shape (replace placeholders with actual state, never fictional times):

```text
[START] role=Lead time=<observed zoned instant>
selected_engineers=N (0–5); reason=<READY independent tasks / real agent slots / ownership / Reviewer throughput>
| Task | Status | Reason | Owner | Branch | Agent start |
| ...  | READY / QUEUED / BLOCKED / NO_READY | concrete reason | Engineer 1 / unassigned | ... | observed / NOT STARTED |
```

N=0 is a legitimate decision: display `NO_READY` or the capacity blocker and its reason, with no invented Engineer. At each real Agent handoff, show that Agent's measured `[START]`, `[END]` and elapsed in the same zone, including Reviewer; never substitute a Lead clock for an Agent's.

At **every terminal final**, even when paused or blocked, print a **complete per-role timing table** with these literal headings:

| Role | Task/state | Start (zone) | End (zone) | Elapsed | Reason/evidence |
|---|---|---|---|---|---|
| Lead | current round | observed time | observed time | measured duration | state transition |
| Engineer 1…N | each dispatched task | own observed time | own observed time / `NOT MEASURED` | measured / `NOT MEASURED` | exact task and missing-measurement reason |
| Reviewer | review state / `NOT STARTED` | own time / `NOT STARTED` | observed / `NOT MEASURED` | measured / `NOT MEASURED` | verdict or why pending |

With N=0, include `Engineer (none)` with `NOT STARTED` and its READY/capacity reason. Include Reviewer even if review is pending; never label an unstarted review complete. Beneath the table, provide **both** `round_elapsed=<measured duration>` (current Lead round start→end) and `first_scope_elapsed=<measured wall-clock duration>` (original first scope start→current end, including waits). Show the corresponding actual start/end instants and effective `zone=<IANA-zone>` with UTC offset. Do not add Agent durations to derive wall-clock elapsed. An unknown historical start is `NOT MEASURED` with a reason, not reset to the current round.

**Terminal final is a hard visibility gate.** `TASKS.md`, a Markdown link, tool log, commentary or a partial final can duplicate timing but **cannot replace** the full role table in the last user-visible final answer.

### Executable actual-chat acceptance gate / 可执行聊天断言

Save the visible CHAT START text and **terminal final** text from the actual conversation as separate UTF-8 files and run this gate. It rejects the known V2.2 failure shape (timing appears only in TASKS/commentary). It checks structure, not whether asserted timestamps actually came from the clock; verify the latter separately:

```sh
CHAT_START_FILE=/path/to/chat-start.txt TERMINAL_FINAL_FILE=/path/to/terminal-final.txt python3 - <<'PY'
import os
import re
from datetime import datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

start = Path(os.environ["CHAT_START_FILE"]).read_text(encoding="utf-8")
final = Path(os.environ["TERMINAL_FINAL_FILE"]).read_text(encoding="utf-8")

def required_reason(value):
    return isinstance(value, str) and value.strip() not in ("", "-", "...", "N/A", "NOT MEASURED")

def field(name):
    matches = re.findall(r"(?:^|\s)" + re.escape(name) + r"=([^\s]+)", final, re.M)
    assert len(matches) == 1, "missing/duplicate " + name
    return matches[0]

lead_starts = re.findall(r"(?m)^\[START\] role=Lead time=(.+?) zone=([^\s]+)\s*$", start)
assert len(lead_starts) == 1, "visible Lead START with real time/zone required"
start_time, start_zone = lead_starts[0]
final_zone = re.findall(r"(?m)^zone=([^\s]+) ([+-][0-9]{2}:[0-9]{2})\s*$", final)
assert len(final_zone) == 1 and final_zone[0][0] == start_zone, "START/FINAL effective zone mismatch"
zone_name, zone_offset = final_zone[0]
zone = ZoneInfo(zone_name)

def timestamp(value):
    assert re.fullmatch(r"[0-9]{4}-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,6})? ?[+-][0-9]{2}:[0-9]{2}", value), "timestamp format"
    instant = datetime.fromisoformat(value)
    assert instant.utcoffset() == instant.astimezone(zone).utcoffset(), "timestamp zone offset mismatch"
    assert instant.strftime("%z") == zone_offset.replace(":", ""), "timestamp offset differs from round zone"
    return instant

def duration(value):
    match = re.fullmatch(r"([0-9]+):([0-5][0-9]):([0-5][0-9])(?:\.([0-9]{1,3}))?", value)
    assert match, "invalid nonempty elapsed duration"
    return timedelta(hours=int(match[1]), minutes=int(match[2]),
                     seconds=int(match[3]), milliseconds=int((match[4] or "0").ljust(3, "0")))

def timed_pair(begin, end, elapsed):
    b, e = timestamp(begin), timestamp(end)
    assert e >= b and abs(((e - b) - duration(elapsed)).total_seconds()) < 1, "invalid start/end/elapsed"
    return b, e

lead_start = timestamp(start_time)
assert "dispatch matrix" in start.lower() or "派工矩阵" in start, "CHAT START dispatch matrix missing"
selection = re.findall(r"selected_engineers=([^;\s]+)", start)
assert len(selection) == 1 and re.fullmatch(r"[0-5]", selection[0]), "selected_engineers must be one integer 0–5"
selected = int(selection[0])
why = re.findall(r"selected_engineers=[^\n]*?reason=([^\n]+)", start)
assert len(why) == 1 and required_reason(why[0]), "dynamic headcount selection reason missing"
header = "| Task | Status | Reason | Owner | Branch | Agent start |"
assert header in start, "CHAT START readiness matrix columns missing"
decision_rows = []
for line in start.splitlines()[start.splitlines().index(header) + 1:]:
    if not line.startswith("|"):
        break
    if re.fullmatch(r"\|[-| ]+\|", line):
        continue
    cells = [cell.strip() for cell in line.strip("|").split("|")]
    assert len(cells) == 6, "incomplete task decision row"
    task, status, reason, owner, branch, agent_start = cells
    assert status in ("READY", "QUEUED", "BLOCKED", "NO_READY"), "invalid readiness status"
    assert required_reason(reason), "missing READY/QUEUED/BLOCKED reason"
    assert task and owner and branch and agent_start, "incomplete task/owner/branch/start"
    if agent_start != "NOT STARTED":
        timestamp(agent_start)
    decision_rows.append(cells)
assert decision_rows, "no visible task decision row"
if selected:
    owners = {row[3] for row in decision_rows if row[1] == "READY"}
    assert all("Engineer " + str(i) in owners for i in range(1, selected + 1)), "selected Agent missing READY task"
else:
    assert not any(row[1] == "READY" and row[3].startswith("Engineer ") for row in decision_rows), "zero Engineers but READY assigned"

table = "| Role | Task/state | Start (zone) | End (zone) | Elapsed | Reason/evidence |"
lines = final.splitlines()
assert table in lines, "terminal final timing table missing"
rows = {}
for line in lines[lines.index(table) + 1:]:
    if not line.startswith("|"):
        break
    if re.fullmatch(r"\|[-| ]+\|", line):
        continue
    cells = [cell.strip() for cell in line.strip("|").split("|")]
    assert len(cells) == 6 and cells[0] not in rows, "incomplete/duplicate role row"
    rows[cells[0]] = cells
expected = {"Lead", "Reviewer"} | ({"Engineer " + str(i) for i in range(1, selected + 1)}
                                  if selected else {"Engineer (none)"})
assert set(rows) == expected, "terminal final must show exactly every real Agent and pending role"
for role, cells in rows.items():
    _, task, begin, end, elapsed, reason = cells
    assert required_reason(task) and required_reason(reason), "missing task/state or evidence/reason"
    assert begin and end and elapsed, "blank start/end/elapsed is never valid"
    if role.startswith("Engineer ") and role != "Engineer (none)":
        assert re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]* (READY|IN_PROGRESS|IN_REVIEW|APPROVED|REJECTED|BLOCKED|DONE)", task), "Engineer task ID/status required"
    if begin == end == elapsed == "NOT STARTED":
        assert role != "Lead" and task == "NOT STARTED", "unstarted role must be explicit"
    elif "NOT MEASURED" in (begin, end, elapsed):
        assert elapsed == "NOT MEASURED" and "NOT STARTED" not in (begin, end), "unknown timing must be labeled"
        for value in (begin, end):
            if value != "NOT MEASURED":
                timestamp(value)
    else:
        timed_pair(begin, end, elapsed)

round_start, round_end = timed_pair(field("round_start"), field("round_end"), field("round_elapsed"))
scope_start, scope_end = timed_pair(field("first_scope_start"), field("first_scope_end"),
                                    field("first_scope_elapsed"))
assert round_start == lead_start and round_end == scope_end and scope_start <= round_start, "Lead round/scope clocks do not align"
lead = rows["Lead"]
assert timestamp(lead[2]) == round_start and timestamp(lead[3]) == round_end
assert abs((duration(lead[4]) - duration(field("round_elapsed"))).total_seconds()) < 1, "Lead row round elapsed differs"
print("VISIBLE-CHAT-CONTRACT PASS (structure and time arithmetic; verify clock provenance separately)")
PY
```

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
| "The Agent runs on UTC, so log UTC." / 机器是 UTC | Convert real instants to the effective repository timezone; default JST, explicit non-managed project zone wins. / 按仓库时区换算 |
| "Just change an offset label." / 只改时区标记 | Recalculate the calendar day and clock hour in the selected zone; never relabel an instant. / 必须真实换算 |
| "Historical first-start used another timezone, reset it." / 历史记录重置 | Preserve original instant/provenance, add a view in the effective repository zone if needed, keep total wall time unchanged. / 保留历史起点 |
| "Times are already in TASKS or commentary, so omit the table from final." / 已写台账不再显示 | The **terminal final** per-role table and both Lead elapsed durations are mandatory user-visible output. / 终局答复必须显式列出 |
| "Dispatch five Engineers to look parallel." / 为展示并行而派满 | Choose `selected_engineers=0–5` from real READY independence, ownership and review capacity; show QUEUED/BLOCKED reasons. / 并行人数不作秀 |
