# Independent UI/UX Acceptance Contract / 独立 UI/UX 验收规范（V2.0）

**Normative whenever a task changes user-visible UI, navigation, interaction, accessibility, localization or layout, or a release requires visual acceptance.** 此规范与代码、构建、自动化测试门禁并列；评分只能补充客观检查，不能抵消失败。

## 1. Scope and prerequisites / 范围与派单前约定

Before dispatch, Lead and the task brief must record:

- `UI_SCOPE=FULL`: UI-affecting feature, visual change, interaction or accessible behavior — **independent full UI/UX acceptance required**.
- `UI_SCOPE=SMOKE`: Backend/API/data change with a plausible UI contract impact — run an independent representative UI smoke path; escalate to `FULL` if behavior or layout changes are found.
- `UI_SCOPE=NA`: Provably no user-facing or UI-contract impact — provide a reason and affected-surface analysis; use `NOT APPLICABLE` for score, **not 100/100**.
- Supported platforms and minimum OS versions; must-work critical user journeys and destructive/safety controls; tested locales, themes, assistive input, viewport/DPI matrix; mandatory commands and release vs merge target.
- Acceptance criteria and target devices are **fixed before dispatch**. A missing required device/platform is a blocker, not a reason to reclassify `FULL` as `NA`.

If requirements are missing or the requested design changes user behavior, Lead obtains user direction instead of inventing accessibility, safety or visual requirements.

## 2. Two-layer acceptance / 双层验收

### A. Hard gates — any failed required gate prevents approval / 客观硬门禁

1. **Critical task completion and recoverability:** independently exercise primary user journeys (success, loading, error, empty/disabled/permission states, retry, cancellation and confirmation), including prevention of accidental destructive actions. No missing or unreachable critical action; undo/confirmation where required by the product.
2. **Layout and resilience:** no clipped/overlapping essential text or controls, invisible confirmation buttons, inaccessible dialogs, unscrollable primary content or unreadable type at supported resolutions, DPI and text sizes. Verify resize and focus after dialogs; account for dynamic text and localizations.
3. **Input and accessibility:** functional keyboard focus order, focus visibility, shortcuts where specified, screen reader/automation names and states where supported, contrast and target sizes applicable to the platform. Critical flows must remain operable with the input modes promised by the product.
4. **Consistency and feedback:** terminology, typography, spacing, alignment, controls, errors, validation and progress indicators are internally coherent; state changes are perceptible. Inspect according to platform design conventions and documented product design tokens.
5. **Regression and platform fidelity:** test the actual supported target environment and commit SHA; web emulator or Linux build alone cannot prove Windows desktop or iOS/Android device behavior.

**Severity / 严重等级**:

| Severity | Definition / 定义 | Gate |
|---|---|---|
| `P0 Critical` | Safety/data-loss risk, destructive action without required protection, unusable core workflow | **Block** |
| `P1 High` | Critical control clipped/hidden, essential path impossible by required keyboard/touch/input, severe required accessibility or layout failure | **Block** |
| `P2 Medium` | Noncritical usability defect, clear but nonblocking inconsistency, recoverable confusing behavior | Record, resolve or explicitly track |
| `P3 Low` | Minor cosmetic polish / 非关键视觉瑕疵 | Record |

`P0/P1` are blocking **regardless of score**. Product-specific safety, regulatory and contractual rules may be stricter. Mandatory tests or platforms that **fail** result in `REJECTED`; mandatory checks that **cannot run** result in `BLOCKED`. A known reproducible defect must be reported even if another environment is unavailable; Lead retains both the defect and missing-evidence risk.

### B. UX quality score — 100 points / 质量评分

The reviewer gives evidence-backed scores per dimension. Each dimension is rated 0–5 then converted by `points = weight × (rating / 5)`. Record rating, evidence and rationale; do not invent measurement or infer all dimensions from a static screenshot.

| Dimension / 维度 | Weight | Observe / 观察 |
|---|---:|---|
| Layout, hierarchy and readability / 布局层级与可读性 | 25 | Key-action prominence, density, text/wrapping, responsive layout |
| Task flow and interaction / 任务与交互 | 25 | Discoverability, feedback, completion steps, error prevention/recovery |
| Visual consistency and polish / 视觉一致性 | 20 | Design tokens, typography, rhythm, component states, platform fit |
| Accessibility and input / 无障碍与输入 | 20 | Keyboard/focus, labels, contrast, target area, text scaling |
| Localization, theme and state coverage / 本地化主题与状态 | 10 | Long translations, light/dark, empty/error/loading states |
| **Total / 总分** | **100** | |

**Merge-ready:** full required code/platform/UI checks pass, no `P0/P1`, score **≥85/100**, Reviewer verdict `APPROVED`.
**Release-ready:** full release-candidate check on its exact SHA, no `P0/P1`, score **≥90/100**, all release-required platforms and tests pass.
A score from 85 to 89 may support merging into an authorized integration branch but **must not** be presented as release-ready. Score <85 => `REJECTED` if evaluated; unmeasurable mandatory dimension/evidence => `BLOCKED`. `SMOKE` checks use pass/fail, not forced 100-point scoring; `NA` has no score.

**These 85/90 scoring thresholds and weights are this team's internal agreed quality policy, not a W3C/Apple/Android certification or an industry-standard rating.** 评分主观部分须有证据，Reviewer 不得以个人喜好替代要求。

## 3. Platform evidence matrix / 平台实测矩阵

Only require platforms **actually supported by this task**. Lead may add product-specific targets, never remove committed user requirements to meet a deadline.

- **Windows desktop (WinForms/WPF/WinUI/other):** cover `1024×768`, `1280×720`, `1366×768`, `1920×1080` and `100%`, `125%`, `150%`, `175%`, `200%` display scale using documented representative combinations, **including small-screen/high-DPI stress cases** `1024×768@150%` and `1024×768@200%` when supported. Do not claim a full 4×5 Cartesian matrix if only a subset ran. Check keyboard Tab/Shift+Tab, focus, modal dialogs, overflow, scaling and per-monitor DPI if applicable. Industrial/minimum screens specified by the project are mandatory even if smaller than the generic examples.
- **iOS/iPadOS:** representative small phone and larger phone/tablet, portrait/landscape where supported, dynamic type, touch targets, VoiceOver/keyboard paths where promised, light/dark theme and a long-string locale. Use simulator or real device per requirements; clearly label which.
- **Android:** representative compact and large phone/tablet, screen density, font scale, orientation, touch targets, TalkBack/keyboard paths where supported, themes and longer locale. Label emulator versus physical device.
- **Web/cross-platform:** documented viewport and browser matrix, zoom/reflow, keyboard focus, labels, responsive navigation, error states; do not conflate a browser-only check with a native app check.
- **Localization:** inspect source language and representative longest-string/plural/RTL cases among **supported** locales; automated pseudo-localization may broaden coverage but does not replace a mandatory real locale. No unsupported platform/language is silently added.

Reference defaults, interpreted per platform/project, include WCAG 2.2 AA and WCAG2ICT **guidance** for non-web software, Apple touch hit regions around **44×44 pt**, Android interactive target around **48×48 dp**, plus Microsoft Windows accessibility and DPI guidance. These do **not** mean 44pt, 48dp and 24 CSS px are interchangeable. Use the applicable native standard, not a universal invented size.

## 4. Independent execution and report / 独立运行与报告

1. Reviewer checks out **the exact candidate SHA** in an isolated environment; records platform/build, window/screen resolution, scaling/font size, theme, locale, input method, device/emulator and test-tool version as applicable.
2. Actually executes required user journeys through app UI automation, browser automation, accessibility inspection or native GUI/simulator/real-device interaction. Screenshots alone or Engineer-supplied screenshots **do not count as independent execution**. Preserve screenshots/video/automation logs when obtainable with steps and SHA; redact secrets and personal information.
3. Record every matrix cell as `PASS`, `FAIL` or `NOT RUN` with why; distinguish automated, simulator and physical-device results. Do not claim all requested DPI combinations passed if untested. If mandatory GUI hardware/runtime is absent, use `BLOCKED` and ask Lead to arrange it, not a Linux-only `APPROVED`.
4. Two independent review passes: **specification/acceptance compliance first**, then **code/architecture/quality** and UI/UX when applicable. Report to Lead; Lead, not Reviewer, assigns remediation. Independently rerun any changed SHA. Review backlog may delay new dispatch.
5. Lead persists a per-task `reviews/<task-id>-ui-ux.md` (or existing equivalent) and links it from canonical `TASKS.md`; Reviewer can supply its report and read-only evidence without editing product files or racing canonical tracker.

### Required report fields / 必填字段

```text
Task ID / exact SHA / reviewer / reviewer [START] [END] elapsed
UI_SCOPE=FULL | SMOKE | NA; merge or release gate
Requirements and critical flows; supported platforms and required matrix
Test run: tool, exact command/action steps, environment, result, exit code if applicable
Matrix: platform | resolution | scale/font | locale/theme/input | PASS/FAIL/NOT RUN | evidence
Findings: P0/P1/P2/P3 | expected vs actual | steps | impact | evidence | owner via Lead
Score (FULL only): layout /25, flow /25, consistency /20, accessibility /20, locale/states /10; total /100; rationale
Code/functional independent test results; skipped and untested items
Verdict: APPROVED | REJECTED | BLOCKED; merge-ready?; release-ready?
Evidence links or paths, residual risks, required follow-up
```

An approval without a reproducible UI/UX evidence matrix for a `FULL` UI change is invalid, even when unit tests pass or the visual appearance looks polished. 审查员需实测可完成性、可达性与布局韧性，不能只给“好看”评语。

## 5. Source anchors / 依据与边界

- [W3C WCAG 2.2](https://www.w3.org/TR/WCAG22/) and [WCAG2ICT](https://www.w3.org/WAI/standards-guidelines/wcag/non-web-ict/) — accessibility criteria and informative non-web guidance, not this team's scoring thresholds.
- [Apple Human Interface Guidelines — Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons) and [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility).
- [Android Developers — app accessibility](https://developer.android.com/guide/topics/ui/accessibility/views/apps-views).
- [Microsoft — Windows accessibility testing](https://learn.microsoft.com/en-us/windows/apps/design/accessibility/accessibility-testing) and [Windows app design best practices](https://learn.microsoft.com/en-us/windows/apps/get-started/best-practices).
- [Nielsen Norman Group — 10 usability heuristics](https://www.nngroup.com/articles/ten-usability-heuristics/) — evaluation heuristic, not an official numeric quality score.
