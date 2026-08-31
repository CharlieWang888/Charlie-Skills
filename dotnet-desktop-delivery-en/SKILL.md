---
name: dotnet-desktop-delivery-en
description: Engineering delivery practices for .NET desktop applications (Avalonia / WPF / WinForms) - the project-root "run script + pack script" convention, a multi-stage release pipeline (Inno Setup installer and Microsoft Store MSIX produced in one run), unit/integration test layering, and a 20+ language localization scheme kept in sync with the installer. This skill should be used when setting up, reviewing, or refactoring packaging and release automation, test project structure, or localization for a .NET desktop application. English version; a Simplified Chinese version ships as "dotnet-desktop-delivery".
---

# .NET Desktop Application Delivery Practices

Packaging, testing, and localization practices for **.NET desktop applications**. Every template is parameterized - replace the placeholders and apply them to a new project.

## Technology Selection

**Prefer .NET 10 + Avalonia.** Two verified core benefits:

| Benefit | Details |
|---|---|
| **Cross-platform** | Ship one codebase to Windows / macOS / Linux by switching the RuntimeIdentifier (`win-x64` / `osx-arm64` / `linux-x64`) |
| **Headless end-to-end testing** | `Avalonia.Headless` runs real UI tests on environments without a display (CI / servers) - no RDP, no interactive desktop session required |

> The patterns in this skill apply equally to WPF and WinForms. Differences are flagged as "WPF note" in each section. The reference implementation comes from a production .NET 8 + WPF project (PersonalNavigator); source files and line numbers are cited so claims can be verified.

---

## 1. Project-Root Dual-Script Convention

Every project root carries exactly two scripts, each with a single responsibility and a uniform name:

| Script | Responsibility |
|---|---|
| `Run Project.vbs` | **Run** the current project directly (double-click to use) |
| `Pack.bat` | **Build the installer** (delegates to `Pack.ps1`) |

### 1.1 Why the run script is VBS instead of .bat

Launching a desktop app from `.bat` or `dotnet run` flashes a **black console window**. Root cause:

- `.bat` is hosted by `cmd.exe`, so a console window always exists
- `dotnet run` is hosted by the `dotnet` host, which also attaches a console

**VBS is hosted by `WScript`, which carries no console**, so launching a WinExe shows only the application UI. This is the cleanest way to eliminate the black window - no setting beyond `OutputType` needs to change.

> Prerequisite: the main project's `OutputType` must be `WinExe` (WPF default; Avalonia templates also default to `WinExe`, just confirm `<OutputType>WinExe</OutputType>`).

Template (the CONFIG block at the top has three constants; edit those three lines for a new project):

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

Design points:
- The `--check` parameter lets pack scripts probe whether the project is runnable without actually launching the app
- Prefer Release, then Debug; only build when neither exists - avoid waiting for a compile on every double-click
- Surface build failures with a `MsgBox` instead of exiting silently

### 1.2 Layered pack script: bat is only a shell, logic lives in ps1

`.bat` does exactly three things: switch to the UTF-8 code page, check that `dotnet` exists, and delegate to PowerShell passing arguments through. The actual pipeline lives in `.ps1` (easier to maintain, supports parameter validation and structured error handling).

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

## 2. The Packaging Pipeline

A single entry point, `Pack.ps1`, selects the output via `-Target`:

| `-Target` | Output |
|---|---|
| `Installer` (default) | Inno Setup installer |
| `MicrosoftStore` | Microsoft Store `.msixupload` |
| `Both` | **Installer first, then the Store package** |

Full stage list (for `Both`, 12 stages; `Installer` has 11):

| # | Stage | Fail-fast gate |
|---|---|---|
| 1 | restore + build Release | ✅ |
| 2 | **Unit tests** | ✅ |
| 3 | **Integration tests** | ✅ |
| 4 | Increment version + self-contained publish | ✅ |
| 5 | Obfuscate (ConfuserEx); require the SHA256 to change | ✅ |
| 6 | Post-obfuscation smoke test + clean generated logs | ✅ |
| 7 | Authenticode signing (exe / dll) | Degrades to an `-unsigned` package without a cert |
| 8 | Compile the Inno Setup installer | ✅ |
| 9 | Sign the installer | ✅ |
| 10 | Silent install - smoke test - uninstall (`-RunInstallerTest`) | Optional |
| 11 | **Microsoft Store MSIX package** (only `Both`) | Required with `-RequireStore`, otherwise degrades to skip |
| 12 | Artifacts ready; print version / path / signing status | — |

### 2.1 Centralized version management

Maintain the version in a single `Version.props`; the script reads and increments the patch number with regex. **Do not** scatter version numbers across csproj files and scripts.

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

### 2.2 Safety guardrails (mandatory around every deletion)

Pack scripts clean staging directories with `Remove-Item -Recurse -Force`. If a path variable is ever mistyped, the result is catastrophic. Three layers of protection:

```powershell
# 1) Force every staging directory to live under <ProjectRoot>\build\
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

# 2) Refuse to delete any tree containing a reparse point (symlink / mount / junction)
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

Third layer: **resolve external tool paths first**, before any cleanup or version increment. Otherwise, when Inno Setup is missing, the version has already been bumped and the source modified before the run fails halfway through.

```powershell
# Resolve the Inno Setup compiler before any staging cleanup or version
# increment so a missing installation cannot leave the source version advanced.
$innoCompiler = Find-InnoCompiler
```

### 2.3 Smoke test: app side + script side

Verify "the app starts, the main window constructs, resource dictionaries load" without **polluting real user data**.

**App side**: recognize the `--smoke-test` argument, run a windowless verification path, and exit with a code.

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
    // ... normal startup
}

private static int RunReleaseSmokeTest()
{
    LanguageManager.LoadLanguage("en-US");
    var window = new MainWindow(initializeTrayIcon: false);  // skip the tray icon to avoid side effects
    window.Measure(new Size(1300, 750));                     // force layout to prove the XAML loads
    // ... assertions as needed, return 0 / non-zero
}
```

> Key: give the main window constructor a switch that skips side effects such as the tray icon, otherwise the smoke test leaves a tray process behind in CI.

**Script side**: redirect `APPDATA` / `LOCALAPPDATA` to an isolated temporary profile and set a timeout.

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

### 2.4 Obfuscation and signing

**Obfuscation**: assert that the output actually changed, otherwise you "think it is protected but it is not".

```powershell
$releaseHash   = (Get-FileHash -LiteralPath (Join-Path $ReleaseDir "MyApp.dll") -Algorithm SHA256).Hash
$protectedHash = (Get-FileHash -LiteralPath $confuserOutputAssembly -Algorithm SHA256).Hash
if ($releaseHash -eq $protectedHash) { throw "ConfuserEx output is identical to the unprotected assembly." }
```

**Signing**: add a timestamp and verify immediately after signing.

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

**Degradation strategy**: without a certificate, do not break development - produce a test package with an `-unsigned` suffix and flag it prominently in the log; only an explicit `-RequireSigning` makes it a hard failure.

### 2.5 Produce both package types in one run

```powershell
param(
    [ValidateSet("Installer", "MicrosoftStore", "Both")]
    [string]$Target = "Installer",
    # ...
    [switch]$RequireStore,   # hard-fail instead of skipping when Store prerequisites are missing
    # ...
)

# "Both" appends a Microsoft Store upload stage after the installer pipeline.
$totalStages = if ($Target -eq "Both") { 12 } else { 11 }

# ... installer stages 1-10 ...

if ($Target -eq "Both") {
    Write-Host "[11/$totalStages] Microsoft Store upload package" -ForegroundColor Yellow
    Invoke-MicrosoftStorePackaging -Required:$RequireStore
}

Write-Host "[$totalStages/$totalStages] Release artifact ready" -ForegroundColor Green
```

In `Both` mode, Store prerequisites (environment variables / wapproj / msbuild) **degrade to a warning and skip**; only `-RequireStore` or `-Target MicrosoftStore` throws - local development is never blocked by CI-only environment variables.

```powershell
function Test-StorePrerequisite {
    param([Parameter(Mandatory)] [string]$Message, [switch]$Required)
    if ($Required) { throw $Message }
    Write-Warning "$Message Skipping Microsoft Store packaging."
    return $false
}
```

---

## 3. Inno Setup Installer

### 3.1 setup.iss skeleton

Use `#ifndef` to give every externally injected variable a default, so the script works both overridden from the command line (`/d`) and when compiled by double-click.

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

Key points:
- `AppId` is a fixed GUID; **upgrades identify the same app through it**; never change it between versions
- `taskkill` in `[UninstallRun]` guarantees the running process is killed before uninstall, otherwise file locks leave uninstall residue
- `Compression=lzma2/max` + `SolidCompression=yes` shrink the package noticeably

### 3.2 Command-line compilation

```powershell
Invoke-NativeCommand $innoCompiler @(
    "/dMyAppVersion=$version",
    "/dSourceDir=$SignedDir",
    "/dInstallerOutputDir=$InstallerDir",
    "/dMyAppOutputSuffix=$outputSuffix",
    $IssFile
) "Installer compilation failed"
```

### 3.3 Installer localization

The languages declared in the `[Languages]` section **map one-to-one with the in-app languages**, and each language binds its own license file.

```iss
[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"; LicenseFile: "Installer\Licenses\LICENSE.en-US.txt"
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"; LicenseFile: "Installer\Licenses\LICENSE.zh-CN.txt"
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"; LicenseFile: "Installer\Licenses\LICENSE.ja.txt"
; Languages Inno Setup does not ship: Default.isl fallback + custom .isl override
Name: "hindi"; MessagesFile: "compiler:Default.isl,Installer\Languages\Hindi.isl"; LicenseFile: "Installer\Licenses\LICENSE.hi.txt"
```

- Languages **shipped** with Inno Setup: `compiler:Languages\Xxx.isl`
- Languages **not shipped**: combined form `compiler:Default.isl,Installer\Languages\Xxx.isl` (the former provides English fallback for untranslated entries, the latter provides the translated part)

Directory convention:

```
Installer/
├── Languages/   custom .isl files (only for languages Inno Setup does not ship)
└── Licenses/    LICENSE.{lang}.txt (one per language)
```

---

## 4. Microsoft Store MSIX Publishing

### 4.1 Directory structure

```
StorePackaging/
├── PersonalNavigator.Store.wapproj        # Windows Application Packaging Project
├── Package.appxmanifest.template          # placeholder template (committed)
└── Package.appxmanifest                   # generated output (not committed, add to .gitignore)
```

### 4.2 Manifest template

`Package.appxmanifest.template` replaces sensitive / volatile identifiers with placeholders:

```xml
<Identity Name="__STORE_IDENTITY_NAME__"
          Publisher="__STORE_PUBLISHER__"
          Version="__STORE_VERSION__" />
<Properties>
  <DisplayName>__STORE_DISPLAY_NAME__</DisplayName>
  ...
</Properties>
```

### 4.3 Packaging flow

```powershell
function Invoke-MicrosoftStorePackaging {
    param([switch]$Required)

    # 1) Three Partner Center identifiers injected via environment variables (CI Secrets)
    $requiredNames = @(
        "MYAPP_STORE_IDENTITY_NAME",
        "MYAPP_STORE_PUBLISHER",
        "MYAPP_STORE_DISPLAY_NAME")
    # ... collect; Test-StorePrerequisite decides throw or skip when missing ...

    # 2) Pad the version to four segments (MSIX requires x.y.z.w)
    $version = (Get-AppVersion) + ".0"

    # 3) Replace placeholders, write UTF-8 without BOM
    $manifest = (Get-Content -LiteralPath $manifestTemplate -Raw).
        Replace("__STORE_IDENTITY_NAME__", $values["MYAPP_STORE_IDENTITY_NAME"]).
        Replace("__STORE_PUBLISHER__",     $values["MYAPP_STORE_PUBLISHER"]).
        Replace("__STORE_DISPLAY_NAME__",  $values["MYAPP_STORE_DISPLAY_NAME"]).
        Replace("__STORE_VERSION__", $version)
    [System.IO.File]::WriteAllText($manifestPath, $manifest, [System.Text.UTF8Encoding]::new($false))

    # 4) Publish the self-contained output first
    Invoke-NativeCommand "dotnet" @(
        "publish", $ProjectFile, "--configuration", $Configuration, "--runtime", $Runtime,
        "--self-contained", "true", "--no-restore", "--output", $storePublishDirectory
    ) "Self-contained Store publish failed"

    # 5) Package with msbuild (wapproj is not supported by dotnet build)
    Invoke-NativeCommand $msBuild.Source @(
        $storeProject, "/t:Rebuild", "/p:Configuration=$Configuration", "/p:Platform=x64",
        "/p:RuntimeIdentifier=$Runtime", "/p:SelfContained=true", "/p:AppxBundle=Never",
        "/p:UapAppxPackageBuildMode=StoreUpload", "/p:AppxPackageDir=$storeDirectory\"
    ) "Microsoft Store MSIX upload packaging failed"

    # 6) Assert the artifact was actually produced
    $uploadPackage = Get-ChildItem -LiteralPath $storeDirectory -Filter "*.msixupload" -File -Recurse | Select-Object -First 1
    if ($null -eq $uploadPackage) { throw "MSIX upload package was not produced." }
}
```

Key points:
- **Use `msbuild`, not `dotnet build`** - `wapproj` is a Windows Application Packaging Project and `dotnet build` does not support it
- `UapAppxPackageBuildMode=StoreUpload` produces the **Store-upload-only** `.msixupload`
- The MSIX version must be **four segments** (`1.1.10.0`) while the app version is usually three; append `.0`
- Prerequisite: the Visual Studio **MSIX Packaging Tools** workload; the script should probe for `msbuild` first and give clear install guidance

---

## 5. Testing Strategy

### 5.1 Project configuration

Reference only what you need in the test project. **Do not pin specific versions** - use the latest stable version compatible with the project's target framework; if the project already references a version, follow it to avoid pulling in parallel versions that conflict.

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <LangVersion>latest</LangVersion>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <!-- Use the latest stable; versions ride along with project upgrades, never hardcode -->
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

> If you must pin versions (for example, reproducible builds), centralize them in `Directory.Packages.props` instead of scattering them across csproj files.

### 5.2 Organize test directories by layer

Mirror the main project structure and give `Integration/` its own folder:

```
MyApp.Tests/
├── Controls/      # custom controls
├── Converters/    # value converters
├── Data/          # data access
├── Integration/   # integration tests (dedicated folder, pairs with the filter split)
├── Models/
├── Performance/   # performance benchmarks
├── Services/
├── ViewModels/
└── Views/
```

### 5.3 Unit / integration split (naming convention + filter)

No `[Category]` attributes needed - use a **namespace/class naming convention** with `dotnet test --filter`:

```powershell
# Unit tests: exclude Integration
Invoke-NativeCommand "dotnet" @(
    "test", $TestProject, "--configuration", $Configuration, "--no-build", "--no-restore",
    "--filter", "FullyQualifiedName!~Integration"
) "Unit tests failed"

# Integration tests: Integration only
Invoke-NativeCommand "dotnet" @(
    "test", $TestProject, "--configuration", $Configuration, "--no-build", "--no-restore",
    "--filter", "FullyQualifiedName~Integration"
) "Integration tests failed"
```

Splitting into two runs pays off because unit tests are fast and run frequently, while integration tests are slow and can be skipped selectively. Both are **mandatory gates in the packaging pipeline** (stages 2 and 3).

### 5.4 Use InMemory for database tests

Data-access tests use `Microsoft.EntityFrameworkCore.InMemory` - no real database files, no cross-test pollution, and no writes into user data directories.

### 5.5 Avalonia Headless end-to-end testing (recommended)

This is the biggest engineering win of choosing Avalonia: **real UI tests without a display**, so CI no longer needs an interactive desktop session or RDP.

Packages:

```
Avalonia.Headless.XUnit     (or Avalonia.Headless.NUnit)
Avalonia.Themes.Fluent      (headless controls need a theme too)
```

Configuration (once per test project):

```csharp
[assembly: AvaloniaTestApplication(typeof(TestAppBuilder))]

public class TestAppBuilder
{
    public static AppBuilder BuildAvaloniaApp() => AppBuilder.Configure<App>()
        .UseHeadless(new AvaloniaHeadlessPlatformOptions());
}
```

Writing tests - use `[AvaloniaTest]` instead of `[Test]`; it runs the test on the UI thread:

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

Isolation level (default `PerTest`; `PerAssembly` speeds up large suites):

```csharp
[assembly: AvaloniaTestIsolation(AvaloniaTestIsolationLevel.PerAssembly)]
```

| Level | Behavior |
|---|---|
| `PerTest` (default) | Rebuilds the Application and Dispatcher per test; fully isolated |
| `PerAssembly` | One Application shared by the whole assembly; faster but **shared state** - you must clean up global state yourself, and parallel execution is not supported |

Debugging tip: when you need to "see" headless tests, use `Avalonia.Headless.Vnc` to connect over VNC and watch the rendered output.

> **MSTest users**: `Avalonia.Headless.XUnit` / `.NUnit` are the official integrations for xUnit / NUnit. If your project is primarily MSTest, reference the core `Avalonia.Headless` package and start the headless AppBuilder yourself in `[TestInitialize]`, managing the Dispatcher. Recommendation: **keep unit tests on MSTest and run UI/end-to-end tests in a dedicated xUnit or NUnit project** - avoid re-inventing the wheel.

> **WPF note**: WPF has no official headless support; UI tests usually need an STA thread plus a real desktop session (e.g., Appium + WinAppDriver). This is a practical reason to pick Avalonia for new projects.

---

## 6. Localization

### 6.1 Directory structure

One XAML `ResourceDictionary` per language:

```
Resources/Languages/
├── en-US.xaml     <- fallback baseline (largest, most complete)
├── zh-CN.xaml
├── zh-TW.xaml
├── ja.xaml
└── ...(other languages)
```

### 6.2 Fallback baseline design (critical)

**Merge `en-US.xaml` permanently in `App.xaml` as the base dictionary**:

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

When switching languages, **only append** the new dictionary (never replace the baseline):

```csharp
public static void LoadLanguage(string langCode)
{
    // 1) Validate + fall back
    if (string.IsNullOrWhiteSpace(langCode) ||
        !SupportedLanguages.Any(l => string.Equals(l.Code, langCode, StringComparison.OrdinalIgnoreCase)))
    {
        LogService.LogWarning($"Unsupported language '{langCode}', falling back to {DefaultLanguageCode}.");
        langCode = DefaultLanguageCode;
    }

    // 2) Build the new dictionary
    var dict = new ResourceDictionary
    {
        Source = new Uri($"Resources/Languages/{langCode}.xaml", UriKind.Relative)
    };

    var mergedDicts = Application.Current.Resources.MergedDictionaries;

    // 3) Remove the previous language dictionary, then append the new one
    if (_currentLanguageDictionary != null)
        mergedDicts.Remove(_currentLanguageDictionary);

    mergedDicts.Add(dict);
    _currentLanguageDictionary = dict;

    ApplyCultureAndDirection(langCode);
    LanguageChanged?.Invoke();
}
```

**Payoff**: when any language misses a key, WPF falls back through the merge chain to `en-US`, so the UI shows English - **a bare key like `SomeKey` is never shown to the user**. This lets you add a language incrementally without translating everything at once.

### 6.3 Getting strings

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

Show the supported-language list using **each language's self-name** (so users recognize their own language):

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

### 6.4 RTL (right-to-left) support

Arabic, Urdu, and similar languages need a mirrored layout:

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

> Key: after switching language you must **iterate all open windows** and set `FlowDirection` on each; setting only new windows misses dialogs that are already open.

### 6.5 Consumption patterns

| Location | Pattern | Takes effect immediately on switch? |
|---|---|---|
| XAML | `{DynamicResource SomeKey}` | ✅ Yes |
| Code | `LanguageManager.GetString("SomeKey")` | ❌ No - re-assign after listening to `LanguageChanged` |

To react immediately from code, subscribe to the event and refresh in the callback:

```csharp
LanguageManager.LanguageChanged += OnLanguageChanged;

private void OnLanguageChanged()
{
    Title = LanguageManager.GetString("AppTitle");
    // ... refresh other code-set text
}
```

> Convention: **use `DynamicResource` in XAML, never `StaticResource`** - `StaticResource` resolves once and will not update after a language switch.

### 6.6 Checklist for adding a new language

1. Copy `Resources/Languages/en-US.xaml` to `{langCode}.xaml` and translate entry by entry (**partial translation is allowed** - missing entries fall back to English automatically)
2. Add `(code, self-name)` to the `LanguageManager.SupportedLanguages` array
3. If the language is RTL (e.g., ar / ur / fa / he), add a branch to the RTL check in `ApplyCultureAndDirection`
4. Put `LICENSE.{langCode}.txt` in `Installer/Licenses/`
5. Add one line to the `[Languages]` section in `setup.iss`
   - Shipped by Inno Setup - `compiler:Languages\Xxx.isl`
   - Not shipped - create `Xxx.isl` in `Installer/Languages/` and use the combined `compiler:Default.isl,Installer\Languages\Xxx.isl` form
6. Run one pack to confirm both the in-app language and the installer language work

---

## 7. Self-Check Checklist

When delivering a new project or reviewing an existing one, confirm each item:

**Scripts**
- [ ] Project root has `Run Project.vbs` (VBS, not bat - no black window)
- [ ] Project root has `Pack.bat` - `Pack.ps1`
- [ ] Both scripts carry a clear CONFIG / usage block at the top

**Packaging**
- [ ] Version centralized in `Version.props` (or `Directory.Build.props`), nothing scattered
- [ ] Path allow-list validation + reparse-point refusal before cleaning any directory
- [ ] External tools (Inno Setup / signtool / msbuild) resolved **before** any file is modified
- [ ] Post-obfuscation assertion that hashes differ
- [ ] Signing adds a timestamp and verifies afterward; without a cert, degrade to `-unsigned` instead of failing
- [ ] Smoke test redirects `APPDATA`/`LOCALAPPDATA` and has a timeout
- [ ] `-Target Both` produces installer + Store package in one run; missing Store prerequisites degrade to skip

**Testing**
- [ ] Unit / integration split via `FullyQualifiedName~Integration`, run as two passes
- [ ] Database tests use InMemory
- [ ] Tests are pipeline gates; failure aborts the run
- [ ] Avalonia projects enable Headless end-to-end tests

**Localization**
- [ ] `App.xaml` permanently merges `en-US.xaml` as the fallback baseline
- [ ] XAML consistently uses `DynamicResource`
- [ ] Code-set text refreshes by listening to `LanguageChanged`
- [ ] RTL languages iterate all windows to set `FlowDirection` after switching
- [ ] In-app language count == `Installer/Licenses/*.txt` count == `setup.iss [Languages]` entry count
