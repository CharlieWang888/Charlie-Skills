---
name: dotnet-desktop-delivery
description: Use when building, packaging, testing, releasing, or localizing .NET desktop applications using Avalonia, WPF, or WinForms, especially Inno Setup installers and Microsoft Store MSIX. 适用于 .NET 桌面应用打包交付、测试分层、多语言及安装包自动化。
---

# .NET Desktop Delivery / .NET 桌面应用交付

This is **one multilingual skill**, with a single discovery entry and two equivalent language references. 此 Skill 只有一个入口，中文与英文使用同一套交付规则。

## Choose the reference / 选择参考文档

| User language / 用户语言 | Read / 读取 |
|---|---|
| 中文 | [references/workflow.zh-CN.md](references/workflow.zh-CN.md) |
| English or other languages | [references/workflow.en.md](references/workflow.en.md) |
| Explicit bilingual comparison / 明确要求双语对照 | Read both / 两份都读取 |

1. Read the selected reference before implementing its delivery workflow. 先阅读选定语言的文档，再实施对应交付流程。
2. Follow the user's requested stack and the repository's existing architecture. Do not silently replace WPF/WinForms with Avalonia or upgrade .NET versions. 尊重当前技术栈与用户要求，不擅自迁移框架或升级版本。
3. Use the relevant sections for run/pack scripts, Inno Setup + MSIX packaging, testing layers, or localization. Apply only the sections pertinent to the task. 按实际任务选择打包、测试或多语言相关章节。
4. Verify build/test commands on the available target platform; report unavailable Windows-specific tools or packaging steps as **not run** rather than successful. 用实际命令验证，无法执行的平台测试需明确标注。
5. Respond in the user's language; keep filenames, commands, identifiers, and version strings unchanged. 使用用户语言回复，保留代码及命令原文。

Do not register each translation as a separate Skill. 翻译文件只是参考资料，不是独立 Skill。
