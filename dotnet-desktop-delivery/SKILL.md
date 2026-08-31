---
name: dotnet-desktop-delivery
description: .NET 桌面应用（Avalonia / WPF / WinForms）的交付工程化实践——项目根目录「运行脚本 + 打包脚本」双脚本约定、多阶段打包流水线（Inno Setup 安装包与微软商店 MSIX 一次产出）、单元与集成测试分层、以及 20+ 语言的多语言与安装包语言同步方案。This skill should be used when setting up, reviewing, or refactoring packaging and release automation, test project structure, or localization for a .NET desktop application. 简体中文版；英文版见 dotnet-desktop-delivery-en。
---

# .NET 桌面应用交付实践

面向 **.NET 桌面应用** 的打包、测试、多语言三块工程化实践。所有模板均已参数化，替换占位符即可套用到新项目。

## 技术栈选型

**优先选用 .NET 10 + Avalonia。** 已验证的两个核心收益：

| 收益 | 说明 |
|---|---|
| **跨平台** | 一套代码发布 Windows / macOS / Linux，只需切换 RuntimeIdentifier（`win-x64` / `osx-arm64` / `linux-x64`） |
| **Headless 端到端测试** | `Avalonia.Headless` 可在无显示器的环境（CI / 服务器）直接跑真实 UI 测试，无需 RDP、无需交互式桌面会话 |

> 本 skill 的模式同样适用于 WPF 与 WinForms。差异点已在各章节用「WPF 注意」标注。参考实现来自一个 .NET 8 + WPF 的生产项目（PersonalNavigator），文中标注了具体文件与行号以便回溯。

---

## 一、项目根目录双脚本约定

每个项目根目录固定放两个脚本，职责单一、命名统一：

| 脚本 | 职责 |
|---|---|
| `Run Project.vbs` | **直接运行**当前项目（双击即用） |
| `Pack.bat` | **生成安装包**（转调 `Pack.ps1`） |

### 1.1 运行脚本为什么用 VBS 而不是 .bat

用 `.bat` 或 `dotnet run` 启动桌面程序时，会闪出一个**黑色控制台窗口**。根因：

- `.bat` 本身由 `cmd.exe` 承载，控制台窗口必然存在
- `dotnet run` 由 `dotnet` 宿主承载，同样附加控制台

**VBS 由 `WScript` 承载，本身不带控制台**，启动 WinExe 时只显示程序 UI。这是消除黑窗最干净的办法，无需改 `OutputType` 之外的任何设置。

> 前提：主工程 `OutputType` 为 `WinExe`（WPF 默认；Avalonia 模板同样默认 `WinExe`，确认 `<OutputType>WinExe</OutputType>` 即可）。

模板（顶部 CONFIG 块三个常量，新项目改这三行即可）：

```vbs
' Run Project.vbs - launches the current project without a console window.
'
' WScript runs without a console, so only the application UI is shown.
' A .bat wrapper or `dotnet run` flashes a black console window instead.
'
' Usage:
'   Run Project.vbs            build if needed, then launch
'   Run Project.vbs --check    do nothing and return success (used by packaging scripts)
'
' To reuse in another project, edit the CONFIG block below.

Option Explicit

' ------------------------------------------------------------- CONFIG -------
Const PROJECT_FILE     = "MyApp.csproj"
Const TARGET_FRAMEWORK = "net10.0"        ' e.g. net10.0, net8.0-windows
Const ASSEMBLY_NAME    = "MyApp"          ' output exe name without extension
' ----------------------------------------------------------------------------

If WScript.Arguments.Count > 0 Then
    If LCase(WScript.Arguments(0)) = "--check" Then WScript.Quit 0
End If

Dim fileSystem, shell, projectRoot, releaseExe, debugExe, projectFile
Dim executablePath, buildCommand, exitCode

Set fileSystem = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

projectRoot = fileSystem.GetParentFolderName(WScript.ScriptFullName)
releaseExe  = fileSystem.BuildPath(projectRoot, "bin\Release\" & TARGET_FRAMEWORK & "\" & ASSEMBLY_NAME & ".exe")
debugExe    = fileSystem.BuildPath(projectRoot, "bin\Debug\"   & TARGET_FRAMEWORK & "\" & ASSEMBLY_NAME & ".exe")
projectFile = fileSystem.BuildPath(projectRoot, PROJECT_FILE)

If fileSystem.FileExists(releaseExe) Then
    executablePath = releaseExe
ElseIf fileSystem.FileExists(debugExe) Then
    executablePath = debugExe
Else
    buildCommand = "cmd.exe /c dotnet build " & Quote(projectFile) & " -c Release"
    exitCode = shell.Run(buildCommand, 0, True)

    If exitCode <> 0 Or Not fileSystem.FileExists(releaseExe) Then
        MsgBox ASSEMBLY_NAME & " could not be built. Please check the .NET SDK installation.", _
               vbCritical, ASSEMBLY_NAME
        WScript.Quit 1
    End If

    executablePath = releaseExe
End If

' WScript runs without a console. The app is a WinExe, so only its UI is shown.
shell.Run Quote(executablePath), 1, False

Function Quote(value)
    Quote = Chr(34) & value & Chr(34)
End Function
```

设计要点：
- `--check` 参数供打包脚本探测项目可运行性，不真正启动程序
- 优先 Release，其次 Debug，都没有才自动构建——避免每次双击都等待编译
- 构建失败用 `MsgBox` 明确提示，而不是静默退出

### 1.2 打包脚本分层：bat 只做壳，逻辑在 ps1

`.bat` 只负责三件事：切 UTF-8 代码页、检测 `dotnet` 是否存在、转调 PowerShell 并透传参数。真正的流水线写在 `.ps1` 里（易于维护、支持参数校验与结构化错误处理）。

```bat
@echo off
chcp 65001 >nul
title MyApp - Build Installer

echo ========================================
echo   MyApp - Build Installer
echo ========================================
echo.
echo   Usage:
echo     Pack.bat                        Inno Setup installer only (default)
echo     Pack.bat -Target Both           installer + Microsoft Store MSIX package
echo     Pack.bat -Target MicrosoftStore Microsoft Store package only
echo.

cd /d "%~dp0"

where dotnet >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] .NET SDK not found.
    pause
    exit /b 1
)

powershell.exe -ExecutionPolicy Bypass -File "%~dp0Pack.ps1" %*

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Installer build failed
    echo Common causes:
    echo   1. Inno Setup 7 not installed - https://jrsoftware.org/isdl.php
    echo   2. Build errors - check output above
    echo   3. Microsoft Store target requires Partner Center env vars and
    echo      Visual Studio MSIX Packaging Tools
    pause
    exit /b %errorlevel%
)

echo.
echo Done. Double-click the generated installer to install the app.
pause
```

---

## 二、打包流水线

单一入口 `Pack.ps1`，通过 `-Target` 选择产物：

| `-Target` | 产物 |
|---|---|
| `Installer`（默认） | Inno Setup 安装包 |
| `MicrosoftStore` | 微软商店 `.msixupload` |
| `Both` | **先出安装包，再出商店包** |

完整阶段（以 `Both` 为例，共 12 阶段；`Installer` 为 11 阶段）：

| # | 阶段 | 失败即中断 |
|---|---|---|
| 1 | restore + build Release | ✅ |
| 2 | **单元测试** | ✅ |
| 3 | **集成测试** | ✅ |
| 4 | 版本号自增 + self-contained publish | ✅ |
| 5 | 代码混淆（ConfuserEx），校验前后 SHA256 必须不同 | ✅ |
| 6 | 混淆后冒烟测试 + 清理生成日志 | ✅ |
| 7 | Authenticode 签名（exe / dll） | 无证书则降级为 `-unsigned` 包 |
| 8 | Inno Setup 编译安装包 | ✅ |
| 9 | 给安装包签名 | ✅ |
| 10 | 静默安装→冒烟→卸载（`-RunInstallerTest`） | 可选 |
| 11 | **微软商店 MSIX 包**（仅 `Both`） | `-RequireStore` 时必需，否则降级跳过 |
| 12 | 产物就绪，打印版本/路径/签名状态 | — |

### 2.1 版本集中管理

用独立的 `Version.props` 单点维护版本，脚本正则读写并自增补丁号。**不要**把版本号散落在 csproj 与脚本里。

```xml
<Project>
  <PropertyGroup>
    <ApplicationVersion>1.1.10</ApplicationVersion>
  </PropertyGroup>
</Project>
```

```powershell
function Get-AppVersion {
    $content = Get-Content -LiteralPath $VersionFile -Raw
    $match = [regex]::Match($content, '<ApplicationVersion>(\d+)\.(\d+)\.(\d+)</ApplicationVersion>')
    if (-not $match.Success) { throw "Version.props does not contain a valid semantic version." }
    return $match.Groups[1].Value + "." + $match.Groups[2].Value + "." + $match.Groups[3].Value
}

function Increment-AppPatchVersion {
    $current = Get-AppVersion
    $parts = $current.Split('.')
    $next = "$($parts[0]).$($parts[1]).$([int]$parts[2] + 1)"
    $content = Get-Content -LiteralPath $VersionFile -Raw
    $updated = $content.Replace(
        "<ApplicationVersion>$current</ApplicationVersion>",
        "<ApplicationVersion>$next</ApplicationVersion>")
    if ($updated -eq $content) { throw "Failed to update Version.props." }
    [System.IO.File]::WriteAllText($VersionFile, $updated, [System.Text.UTF8Encoding]::new($false))
    return $next
}
```

### 2.2 安全护栏（删除操作务必加）

打包脚本会 `Remove-Item -Recurse -Force` 清理暂存目录。一旦路径变量被写错，后果是灾难性的。三层防护：

```powershell
# 1) 强制所有暂存目录必须位于 <ProjectRoot>\build\ 之下
function Assert-SafeStagePath {
    param([Parameter(Mandatory)] [string]$Path)
    $resolvedRoot = $ProjectRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar)
    $resolvedPath = [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
    $expectedPrefix = $resolvedRoot + [System.IO.Path]::DirectorySeparatorChar + "build" + [System.IO.Path]::DirectorySeparatorChar
    if ($resolvedPath -eq $resolvedRoot -or
        -not $resolvedPath.StartsWith($expectedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to modify unsafe staging path: $resolvedPath"
    }
    return $resolvedPath
}

# 2) 拒绝删除包含 reparse point（符号链接 / 挂载点 / Junction）的目录树
function Reset-StageDirectory {
    param([Parameter(Mandatory)] [string]$Path)
    $safePath = Assert-SafeStagePath $Path
    if (Test-Path -LiteralPath $safePath) {
        $item = Get-Item -LiteralPath $safePath -Force
        if (-not $item.PSIsContainer) { throw "Staging path is not a directory: $safePath" }
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Refusing to traverse a reparse point: $safePath"
        }
        $pending = [System.Collections.Generic.Stack[string]]::new()
        $pending.Push($safePath)
        while ($pending.Count -gt 0) {
            $current = $pending.Pop()
            foreach ($child in Get-ChildItem -LiteralPath $current -Force) {
                if (($child.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                    throw "Refusing to remove a staging tree containing a reparse point: $($child.FullName)"
                }
                if ($child.PSIsContainer) { $pending.Push($child.FullName) }
            }
        }
        Remove-Item -LiteralPath $safePath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $safePath -Force | Out-Null
    return $safePath
}
```

第三层：**外部工具路径在最前面解析**，早于任何清理与版本号自增。否则 Inno Setup 没装时，版本号已经被推进、源码已被改动，却在中途失败。

```powershell
# Resolve the Inno Setup compiler before any staging cleanup or version
# increment so a missing installation cannot leave the source version advanced.
$innoCompiler = Find-InnoCompiler
```

### 2.3 冒烟测试：应用侧 + 脚本侧配合

验证「程序能启动、能构造主窗口、资源字典能加载」，且**不污染真实用户数据**。

**应用侧**：识别 `--smoke-test` 参数，走无窗口验证路径并以退出码结束。

```csharp
protected override async void OnStartup(StartupEventArgs e)
{
    base.OnStartup(e);

    if (e.Args.Any(argument => string.Equals(argument, "--smoke-test", StringComparison.OrdinalIgnoreCase)))
    {
        var exitCode = RunReleaseSmokeTest();
        Environment.ExitCode = exitCode;
        Shutdown(exitCode);
        return;
    }
    // ... 正常启动
}

private static int RunReleaseSmokeTest()
{
    LanguageManager.LoadLanguage("en-US");
    var window = new MainWindow(initializeTrayIcon: false);  // 不初始化托盘，避免副作用
    window.Measure(new Size(1300, 750));                     // 触发布局，验证 XAML 可加载
    // ... 必要的断言，返回 0 / 非 0
}
```

> 关键：给主窗口构造函数留一个跳过托盘图标等副作用的开关，否则冒烟测试会在 CI 里残留托盘进程。

**脚本侧**：把 `APPDATA` / `LOCALAPPDATA` 重定向到隔离的临时 profile，并设超时。

```powershell
function Invoke-SmokeTest {
    param([Parameter(Mandatory)] [string]$Executable, [Parameter(Mandatory)] [string]$ProfileRoot)

    Reset-StageDirectory $ProfileRoot | Out-Null
    $roaming = Join-Path $ProfileRoot "Roaming"
    $local   = Join-Path $ProfileRoot "Local"
    New-Item -ItemType Directory -Path $roaming, $local -Force | Out-Null

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $Executable
    $startInfo.Arguments = "--smoke-test"
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.Environment["APPDATA"] = $roaming
    $startInfo.Environment["LOCALAPPDATA"] = $local
    $startInfo.Environment["MYAPP_DATA_DIR"] = (Join-Path $ProfileRoot "MyApp")

    $process = [System.Diagnostics.Process]::Start($startInfo)
    if ($null -eq $process) { throw "Smoke test process could not be started." }
    if (-not $process.WaitForExit(30000)) {
        $process.Kill($true)
        throw "Smoke test timed out."
    }
    if ($process.ExitCode -ne 0) { throw "Smoke test failed with exit code $($process.ExitCode)." }
}
```

### 2.4 混淆与签名

**混淆**：必须校验产物确实被改写，否则「以为加了壳其实没加」。

```powershell
$releaseHash   = (Get-FileHash -LiteralPath (Join-Path $ReleaseDir "MyApp.dll") -Algorithm SHA256).Hash
$protectedHash = (Get-FileHash -LiteralPath $confuserOutputAssembly -Algorithm SHA256).Hash
if ($releaseHash -eq $protectedHash) { throw "ConfuserEx output is identical to the unprotected assembly." }
```

**签名**：加时间戳，并签名后立即验证。

```powershell
function Sign-And-Verify {
    param([Parameter(Mandatory)] [string]$SignTool, [Parameter(Mandatory)] [string]$FilePath)
    Invoke-NativeCommand $SignTool @(
        "sign", "/sha1", $SigningCertificateThumbprint,
        "/fd", "SHA256", "/tr", $TimestampUrl, "/td", "SHA256", $FilePath
    ) "Authenticode signing failed for $FilePath"
    Invoke-NativeCommand $SignTool @("verify", "/pa", "/v", $FilePath) "Signature verification failed for $FilePath"
}
```

**降级策略**：没有证书时不要中断研发，产出带 `-unsigned` 后缀的测试包并在日志中显著标注；只有显式 `-RequireSigning` 才硬失败。

### 2.5 一次产出两类包

```powershell
param(
    [ValidateSet("Installer", "MicrosoftStore", "Both")]
    [string]$Target = "Installer",
    # ...
    [switch]$RequireStore,   # Store 前置条件缺失时改为硬失败，而非跳过
    # ...
)

# "Both" appends a Microsoft Store upload stage after the installer pipeline.
$totalStages = if ($Target -eq "Both") { 12 } else { 11 }

# ... 安装包阶段 1-10 ...

if ($Target -eq "Both") {
    Write-Host "[11/$totalStages] Microsoft Store upload package" -ForegroundColor Yellow
    Invoke-MicrosoftStorePackaging -Required:$RequireStore
}

Write-Host "[$totalStages/$totalStages] Release artifact ready" -ForegroundColor Green
```

商店打包的前置条件（环境变量 / wapproj / msbuild）在 `Both` 模式下**降级为警告并跳过**，只有 `-RequireStore` 或 `-Target MicrosoftStore` 时才抛错——本地开发不会被 CI 专用的环境变量卡住。

```powershell
function Test-StorePrerequisite {
    param([Parameter(Mandatory)] [string]$Message, [switch]$Required)
    if ($Required) { throw $Message }
    Write-Warning "$Message Skipping Microsoft Store packaging."
    return $false
}
```

---

## 三、Inno Setup 安装包

### 3.1 setup.iss 骨架

用 `#ifndef` 给每个外部注入的变量提供默认值，使脚本既能被命令行 `/d` 覆盖，也能独立双击编译。

```iss
#define MyAppName "MyApp"
#define MyAppPublisher "Your Company"
#define MyAppURL "https://example.com"
#define MyAppExeName "MyApp.exe"

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

#ifndef SourceDir
  #define SourceDir "build\signed"
#endif

#ifndef InstallerOutputDir
  #define InstallerOutputDir "build\installer"
#endif

#ifndef MyAppOutputSuffix
  #define MyAppOutputSuffix ""
#endif

[Setup]
AppId={{YOUR-GUID-HERE}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
OutputDir={#InstallerOutputDir}
OutputBaseFilename=MyApp-Setup-v{#MyAppVersion}{#MyAppOutputSuffix}
Compression=lzma2/max
SolidCompression=yes

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{cmd}"; Parameters: "/c ""taskkill /f /im {#MyAppExeName}"""; Flags: runhidden; RunOnceId: "TerminateMyApp"
```

要点：
- `AppId` 用固定 GUID，**升级安装靠它识别同一应用**；勿随版本变动
- `[UninstallRun]` 里 `taskkill` 确保卸载时能杀掉仍在运行的进程，否则文件占用导致卸载残留
- `Compression=lzma2/max` + `SolidCompression=yes` 显著减小体积

### 3.2 命令行编译

```powershell
Invoke-NativeCommand $innoCompiler @(
    "/dMyAppVersion=$version",
    "/dSourceDir=$SignedDir",
    "/dInstallerOutputDir=$InstallerDir",
    "/dMyAppOutputSuffix=$outputSuffix",
    $IssFile
) "Installer compilation failed"
```

### 3.3 安装包多语言

`[Languages]` 段声明的语言与**应用内语言一一对应**，并为每种语言绑定对应许可证文件。

```iss
[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"; LicenseFile: "Installer\Licenses\LICENSE.en-US.txt"
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"; LicenseFile: "Installer\Licenses\LICENSE.zh-CN.txt"
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"; LicenseFile: "Installer\Licenses\LICENSE.ja.txt"
; Inno Setup 未内置的语言：用 Default.isl 兜底 + 自定义 .isl 覆盖
Name: "hindi"; MessagesFile: "compiler:Default.isl,Installer\Languages\Hindi.isl"; LicenseFile: "Installer\Licenses\LICENSE.hi.txt"
```

- Inno Setup **内置**的语言：`compiler:Languages\Xxx.isl`
- **未内置**的语言：组合写法 `compiler:Default.isl,Installer\Languages\Xxx.isl`（前者提供未翻译条目的英文兜底，后者提供已翻译部分）

目录约定：

```
Installer/
├── Languages/   自定义 .isl（仅放 Inno Setup 未内置的语言）
└── Licenses/    LICENSE.{lang}.txt（每种语言一份）
```

---

## 四、微软商店 MSIX 上架

### 4.1 目录结构

```
StorePackaging/
├── PersonalNavigator.Store.wapproj        # Windows Application Packaging Project
├── Package.appxmanifest.template          # 占位符模板（入库）
└── Package.appxmanifest                   # 生成物（不入库，加入 .gitignore）
```

### 4.2 清单模板

`Package.appxmanifest.template` 用占位符替换敏感/易变标识：

```xml
<Identity Name="__STORE_IDENTITY_NAME__"
          Publisher="__STORE_PUBLISHER__"
          Version="__STORE_VERSION__" />
<Properties>
  <DisplayName>__STORE_DISPLAY_NAME__</DisplayName>
  ...
</Properties>
```

### 4.3 打包流程

```powershell
function Invoke-MicrosoftStorePackaging {
    param([switch]$Required)

    # 1) 三个 Partner Center 标识，由环境变量注入（CI Secrets）
    $requiredNames = @(
        "MYAPP_STORE_IDENTITY_NAME",
        "MYAPP_STORE_PUBLISHER",
        "MYAPP_STORE_DISPLAY_NAME")
    # ... 收集，缺失则 Test-StorePrerequisite 决定 throw 或 skip ...

    # 2) 版本号补成四段（MSIX 强制要求 x.y.z.w）
    $version = (Get-AppVersion) + ".0"

    # 3) 占位符替换，UTF-8 无 BOM 写出
    $manifest = (Get-Content -LiteralPath $manifestTemplate -Raw).
        Replace("__STORE_IDENTITY_NAME__", $values["MYAPP_STORE_IDENTITY_NAME"]).
        Replace("__STORE_PUBLISHER__",     $values["MYAPP_STORE_PUBLISHER"]).
        Replace("__STORE_DISPLAY_NAME__",  $values["MYAPP_STORE_DISPLAY_NAME"]).
        Replace("__STORE_VERSION__", $version)
    [System.IO.File]::WriteAllText($manifestPath, $manifest, [System.Text.UTF8Encoding]::new($false))

    # 4) 先 publish 自包含产物
    Invoke-NativeCommand "dotnet" @(
        "publish", $ProjectFile, "--configuration", $Configuration, "--runtime", $Runtime,
        "--self-contained", "true", "--no-restore", "--output", $storePublishDirectory
    ) "Self-contained Store publish failed"

    # 5) 用 msbuild 打包（wapproj 不支持 dotnet build）
    Invoke-NativeCommand $msBuild.Source @(
        $storeProject, "/t:Rebuild", "/p:Configuration=$Configuration", "/p:Platform=x64",
        "/p:RuntimeIdentifier=$Runtime", "/p:SelfContained=true", "/p:AppxBundle=Never",
        "/p:UapAppxPackageBuildMode=StoreUpload", "/p:AppxPackageDir=$storeDirectory\"
    ) "Microsoft Store MSIX upload packaging failed"

    # 6) 校验产物确实生成
    $uploadPackage = Get-ChildItem -LiteralPath $storeDirectory -Filter "*.msixupload" -File -Recurse | Select-Object -First 1
    if ($null -eq $uploadPackage) { throw "MSIX upload package was not produced." }
}
```

关键点：
- **必须用 `msbuild` 而非 `dotnet build`**——`wapproj` 是 Windows Application Packaging Project，`dotnet build` 不支持
- `UapAppxPackageBuildMode=StoreUpload` 产出**上架专用**的 `.msixupload`
- MSIX 版本必须是**四段**（`1.1.10.0`），而应用版本通常三段，需补 `.0`
- 前置依赖：Visual Studio 的 **MSIX Packaging Tools** 工作负载；脚本应先探测 `msbuild` 并给出明确安装指引

---

## 五、测试策略

### 5.1 工程配置

测试工程只引用必要依赖。**不锁定具体版本号**，使用与项目目标框架兼容的最新稳定版；若项目已引用某版本，优先跟随项目现有版本，避免并行引入多个版本造成冲突。

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <LangVersion>latest</LangVersion>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <!-- 使用最新稳定版；版本随项目升级，不写死 -->
    <PackageReference Include="MSTest" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.InMemory" />
  </ItemGroup>

  <ItemGroup>
    <Using Include="Microsoft.VisualStudio.TestTools.UnitTesting" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\MyApp\MyApp.csproj" />
  </ItemGroup>
</Project>
```

> 若需锁定版本（如可复现构建要求），用 `Directory.Packages.props` 集中管理，而不是散落在各 csproj。

### 5.2 目录按层组织

测试目录镜像主工程结构，并**单独分出 `Integration/`**：

```
MyApp.Tests/
├── Controls/      # 自定义控件
├── Converters/    # 值转换器
├── Data/          # 数据访问
├── Integration/   # 集成测试（单独目录，配合 filter 分离）
├── Models/
├── Performance/   # 性能基准
├── Services/
├── ViewModels/
└── Views/
```

### 5.3 单元 / 集成分离（靠命名约定 + filter）

不需要给测试打 `[Category]` 标签，用**命名空间/类名约定**配合 `dotnet test --filter` 即可：

```powershell
# 单元测试：排除 Integration
Invoke-NativeCommand "dotnet" @(
    "test", $TestProject, "--configuration", $Configuration, "--no-build", "--no-restore",
    "--filter", "FullyQualifiedName!~Integration"
) "Unit tests failed"

# 集成测试：只要 Integration
Invoke-NativeCommand "dotnet" @(
    "test", $TestProject, "--configuration", $Configuration, "--no-build", "--no-restore",
    "--filter", "FullyQualifiedName~Integration"
) "Integration tests failed"
```

分成两次跑的好处：单元测试快、可高频执行；集成测试慢、可选择性跳过。二者**都是打包流水线的必经门禁**（阶段 2、3）。

### 5.4 数据库测试用 InMemory

数据访问相关测试使用 `Microsoft.EntityFrameworkCore.InMemory`，不碰真实数据库文件，避免测试间互相污染、也避免把测试写进用户数据目录。

### 5.5 Avalonia Headless 端到端测试（推荐）

这是选用 Avalonia 的最大工程收益：**无需显示器即可运行真实 UI 测试**，CI 里不再需要配置交互式桌面会话或 RDP。

安装包：

```
Avalonia.Headless.XUnit     （或 Avalonia.Headless.NUnit）
Avalonia.Themes.Fluent      （无头控件同样需要主题）
```

配置（每个测试工程一次）：

```csharp
[assembly: AvaloniaTestApplication(typeof(TestAppBuilder))]

public class TestAppBuilder
{
    public static AppBuilder BuildAvaloniaApp() => AppBuilder.Configure<App>()
        .UseHeadless(new AvaloniaHeadlessPlatformOptions());
}
```

编写测试——用 `[AvaloniaTest]` 替代 `[Test]`，它负责在 UI 线程上执行：

```csharp
[AvaloniaTest]
public void Should_Type_Text_Into_TextBox()
{
    var textBox = new TextBox();
    var window = new Window { Content = textBox };

    window.Show();
    textBox.Focus();
    window.KeyTextInput("Hello World");

    Assert.AreEqual("Hello World", textBox.Text);
}
```

隔离级别（默认 `PerTest`，大套件可提速）：

```csharp
[assembly: AvaloniaTestIsolation(AvaloniaTestIsolationLevel.PerAssembly)]
```

| 级别 | 行为 |
|---|---|
| `PerTest`（默认） | 每个测试重建 Application 与 Dispatcher，完全隔离 |
| `PerAssembly` | 整个程序集复用一个 Application，更快但**共享状态**，需自行清理全局状态，且不支持并发执行 |

调试技巧：需要"看见"无头测试时，使用 `Avalonia.Headless.Vnc` 通过 VNC 连接观察渲染结果。

> **MSTest 用户注意**：`Avalonia.Headless.XUnit` / `.NUnit` 是官方对 xUnit / NUnit 的集成。若项目主用 MSTest，可引用核心包 `Avalonia.Headless`，在 `[TestInitialize]` 中自行启动 headless AppBuilder 并管理 Dispatcher。建议：**单元测试沿用 MSTest，UI/端到端测试单独用 xUnit 或 NUnit 工程**，避免重复造轮子。

> **WPF 注意**：WPF 没有官方 headless 支持，UI 测试通常需要 STA 线程 + 真实桌面会话（如 Appium + WinAppDriver）。这也是推荐新项目选 Avalonia 的实操理由。

---

## 六、多语言方案

### 6.1 目录结构

每种语言一个 XAML `ResourceDictionary`：

```
Resources/Languages/
├── en-US.xaml     ← 回退基准（最多、最全）
├── zh-CN.xaml
├── zh-TW.xaml
├── ja.xaml
└── ...（其余语言）
```

### 6.2 回退基准设计（关键）

**在 `App.xaml` 中常驻合并 `en-US.xaml` 作为基字典**：

```xml
<Application.Resources>
    <ResourceDictionary>
        <ResourceDictionary.MergedDictionaries>
            <!-- Default language dictionary loaded at startup to satisfy XAML resources -->
            <ResourceDictionary Source="Resources/Languages/en-US.xaml" />
        </ResourceDictionary.MergedDictionaries>
    </ResourceDictionary>
</Application.Resources>
```

切换语言时**只追加**新字典（不替换基字典）：

```csharp
public static void LoadLanguage(string langCode)
{
    // 1) 校验 + 回落
    if (string.IsNullOrWhiteSpace(langCode) ||
        !SupportedLanguages.Any(l => string.Equals(l.Code, langCode, StringComparison.OrdinalIgnoreCase)))
    {
        LogService.LogWarning($"Unsupported language '{langCode}', falling back to {DefaultLanguageCode}.");
        langCode = DefaultLanguageCode;
    }

    // 2) 构造新字典
    var dict = new ResourceDictionary
    {
        Source = new Uri($"Resources/Languages/{langCode}.xaml", UriKind.Relative)
    };

    var mergedDicts = Application.Current.Resources.MergedDictionaries;

    // 3) 移除上一次的语言字典，再追加新的
    if (_currentLanguageDictionary != null)
        mergedDicts.Remove(_currentLanguageDictionary);

    mergedDicts.Add(dict);
    _currentLanguageDictionary = dict;

    ApplyCultureAndDirection(langCode);
    LanguageChanged?.Invoke();
}
```

**收益**：任意语言缺 key 时，WPF 沿合并链回退到 `en-US`，界面显示英文——**绝不会把 `SomeKey` 这样的裸 key 显示给用户**。这使得新增语言可以渐进翻译，不必一次补齐全部词条。

### 6.3 字符串获取

```csharp
public static string GetString(string key)
    => Application.Current?.TryFindResource(key)?.ToString() ?? key;

public static string GetString(string key, params object[] args)
{
    var template = GetString(key);
    try { return string.Format(template, args); }
    catch (Exception exception)
    {
        LogService.LogError($"Failed to format resource '{key}'.", exception);
        return template;
    }
}
```

支持的语言列表用**各语言自称**展示（让用户看懂自己的语言）：

```csharp
public static readonly (string Code, string DisplayName)[] SupportedLanguages =
[
    ("en-US", "English"),
    ("zh-CN", "简体中文"),
    ("zh-TW", "繁體中文"),
    ("ja",    "日本語"),
    ("ar",    "العربية"),
    // ...
];
```

### 6.4 RTL（从右到左）支持

阿拉伯语、乌尔都语等需要整体镜像布局：

```csharp
private static void ApplyCultureAndDirection(string langCode)
{
    CultureInfo culture;
    try { culture = CultureInfo.GetCultureInfo(langCode); }
    catch (CultureNotFoundException exception)
    {
        LogService.LogError($"Invalid culture code: {langCode}", exception);
        culture = CultureInfo.GetCultureInfo(DefaultLanguageCode);
    }

    CultureInfo.DefaultThreadCurrentCulture = culture;
    CultureInfo.DefaultThreadCurrentUICulture = culture;

    CurrentFlowDirection = langCode is "ar" or "ur"
        ? FlowDirection.RightToLeft
        : FlowDirection.LeftToRight;

    if (Application.Current is null) return;
    foreach (Window window in Application.Current.Windows)
        window.FlowDirection = CurrentFlowDirection;
}
```

> 要点：切换语言后必须**遍历已打开的窗口**逐个设置 `FlowDirection`，只设新窗口会漏掉已打开的对话框。

### 6.5 消费方式

| 位置 | 写法 | 语言切换是否即时生效 |
|---|---|---|
| XAML | `{DynamicResource SomeKey}` | ✅ 即时 |
| 代码 | `LanguageManager.GetString("SomeKey")` | ❌ 需监听 `LanguageChanged` 事件后重新赋值 |

代码里若要即时响应，订阅事件并在回调中重刷：

```csharp
LanguageManager.LanguageChanged += OnLanguageChanged;

private void OnLanguageChanged()
{
    Title = LanguageManager.GetString("AppTitle");
    // ... 重刷其他代码设置的文本
}
```

> 统一约定：**XAML 用 `DynamicResource` 而非 `StaticResource`**——`StaticResource` 只解析一次，切换语言后不会更新。

### 6.6 新增一门语言的检查清单

1. 复制 `Resources/Languages/en-US.xaml` 为 `{langCode}.xaml`，逐条翻译（**允许先不翻完**——缺失项会自动回退英文）
2. 在 `LanguageManager.SupportedLanguages` 数组中加入 `(code, 自称)`
3. 若该语言为 RTL（如 ar / ur / fa / he），加入 `ApplyCultureAndDirection` 的 RTL 判断分支
4. 在 `Installer/Licenses/` 放 `LICENSE.{langCode}.txt`
5. 在 `setup.iss` 的 `[Languages]` 段加一行
   - Inno Setup 内置 → `compiler:Languages\Xxx.isl`
   - 未内置 → 在 `Installer/Languages/` 新建 `Xxx.isl`，用 `compiler:Default.isl,Installer\Languages\Xxx.isl` 组合写法
6. 跑一次打包，确认应用内语言与安装包语言均正确

---

## 七、自检清单

交付一个新项目或评审既有项目时，逐项确认：

**脚本**
- [ ] 根目录有 `Run Project.vbs`（VBS 而非 bat，无黑窗）
- [ ] 根目录有 `Pack.bat` → `Pack.ps1`
- [ ] 两个脚本顶部均有清晰的 CONFIG / 参数说明

**打包**
- [ ] 版本号集中在 `Version.props`（或 `Directory.Build.props`），无散落
- [ ] 清理目录前有路径白名单校验 + reparse point 拒删
- [ ] 外部工具（Inno Setup / signtool / msbuild）在改动任何文件**之前**解析
- [ ] 混淆后有「前后哈希必须不同」的断言
- [ ] 签名加时间戳并签名后验证；无证书时降级为 `-unsigned` 而非中断
- [ ] 冒烟测试重定向 `APPDATA`/`LOCALAPPDATA`，且有超时
- [ ] `-Target Both` 能一次产出安装包 + 商店包；商店前置缺失时可降级跳过

**测试**
- [ ] 单元 / 集成靠 `FullyQualifiedName~Integration` 分离，分两次跑
- [ ] 数据库测试用 InMemory
- [ ] 测试是打包流水线的门禁，失败即中断
- [ ] Avalonia 项目已启用 Headless 端到端测试

**多语言**
- [ ] `App.xaml` 常驻 `en-US.xaml` 作为回退基准
- [ ] XAML 统一用 `DynamicResource`
- [ ] 代码设置的文本监听 `LanguageChanged` 事件刷新
- [ ] RTL 语言切换后遍历所有窗口设置 `FlowDirection`
- [ ] 应用语言数 == `Installer/Licenses/*.txt` 数 == `setup.iss [Languages]` 条目数
