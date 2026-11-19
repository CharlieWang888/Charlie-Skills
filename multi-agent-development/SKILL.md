---
name: multi-agent-development
description: Use when coordinating continuing software development with multiple coding agents, independent review, persistent task tracking, Git branch isolation, or repeated implement-test-review-fix-merge cycles. 适用于主会话统筹双工程师、独立验收及持续开发任务。
---

# Multi-Agent Development / 多 Agent 自主软件开发

One workflow, one Skill entry, two language references. **The language changes the explanation, not the task state machine or quality gates.** 单一 Skill 入口，语言只影响说明，不改变任务状态与验收标准。

## Choose the reference / 选择参考文档

| User language / 用户语言 | Read / 读取 |
|---|---|
| 中文 | [references/workflow.zh-CN.md](references/workflow.zh-CN.md) |
| English or other languages | [references/workflow.en.md](references/workflow.en.md) |
| Explicit bilingual comparison / 明确要求双语对照 | Read both / 两份都读取 |

1. Read the selected language's full workflow before dispatching tasks; do not treat this short router as the full procedure. 派单前完整阅读所选语言的工作流。
2. The main conversation acts as Lead, with at most two engineering subagents and one independent reviewer; obey the runtime's actual agent and tool availability. 主会话担任 Lead，最多两名工程师与一名审查员，不能虚构可用能力。
3. Persist canonical task status in the repository; require reproducible testing, review of the exact SHA, and Lead-authorized integration. 在仓库保存任务状态，按真实测试与固定 SHA 复审，经授权后合并。
4. Preserve unmerged or uncommitted work and respect protected branches; report blocked tests or missing permissions honestly. 保留未合并和未提交成果，遵守权限与保护分支规则。
5. Respond in the user's language; keep Git branch names, status tokens, commands and SHA values unchanged. 使用用户语言沟通，保持技术标识不变。

Do not load two separate language Skills for the same task. 同一任务不应重复加载两个语言 Skill。
