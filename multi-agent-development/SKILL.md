---
name: multi-agent-development
description: Use when coordinating software development with multiple agents, independent review, persistent task tracking, Git branch isolation, or implement-test-review-merge cycles; also when binding AGENTS.md to mandatory multi-agent workflow and tracking per-agent, subtask, and total elapsed time. 适用于强绑定仓库协同开发及记录耗时。
---

# Multi-Agent Development / 多 Agent 自主软件开发

One workflow, one Skill entry, two language references. **The language changes the explanation, not the task state machine or quality gates.** 单一 Skill 入口，语言只影响说明，不改变任务状态与验收标准。

## Mandatory repository gate / 仓库强绑定门禁

**On EVERY invocation**, before assigning any development work, read [references/repository-binding.md](references/repository-binding.md) completely and enforce its managed block in the target repository root `AGENTS.md`. Create the file if absent; otherwise update the marked section without overwriting existing rules. Commit/push the binding within the user's authorized workflow. If this cannot be safely done, report `BLOCKED` and request direction—never claim a binding that was not persisted. **每次使用本 Skill 都必须检查并写入项目根目录 `AGENTS.md`，持久强制后续多 Agent 协同。**

Immediately print the real start timestamp (including timezone) and start a Lead round timer. On every stop, report the actual end timestamp and elapsed time; record each agent/subtask time and overall project elapsed time in `TASKS.md` or its equivalent. **总历时、单轮耗时、各 Agent 与小任务耗时必须区分；并行时长不得直接相加当作总耗时。** See the binding reference for exact fields and a reusable `AGENTS.md` block.


## Choose the reference / 选择参考文档

| User language / 用户语言 | Read / 读取 |
|---|---|
| 中文 | [references/workflow.zh-CN.md](references/workflow.zh-CN.md) |
| English or other languages | [references/workflow.en.md](references/workflow.en.md) |
| Explicit bilingual comparison / 明确要求双语对照 | Read both / 两份都读取 |

1. Read both the mandatory repository-binding reference above and the selected language's full workflow before dispatching tasks; do not treat this short router as the full procedure. 派单前必须完整阅读强绑定模板和所选语言工作流。
2. Enforce the `AGENTS.md` gate and clock/reporting contract before dispatch; confirm the binding is persisted or report `BLOCKED`. 派单前完成强绑定和计时门禁。
3. The main conversation acts as Lead, with at most two engineering subagents and one independent reviewer; obey the runtime's actual agent and tool availability. 主会话担任 Lead，最多两名工程师与一名审查员，不能虚构可用能力。
4. Persist canonical task status in the repository; require reproducible testing, review of the exact SHA, and Lead-authorized integration. 在仓库保存任务状态，按真实测试与固定 SHA 复审，经授权后合并。
5. Preserve unmerged or uncommitted work and respect protected branches; report blocked tests or missing permissions honestly. 保留未合并和未提交成果，遵守权限与保护分支规则。
6. Respond in the user's language; keep Git branch names, status tokens, commands and SHA values unchanged. 使用用户语言沟通，保持技术标识不变。

Do not load two separate language Skills for the same task. 同一任务不应重复加载两个语言 Skill。
