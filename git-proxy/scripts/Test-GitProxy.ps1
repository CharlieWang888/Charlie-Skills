<#
.SYNOPSIS
    Decide how a git command should reach the remote: direct, or through the
    v2rayN / Clash local proxy that actually answers.

.DESCRIPTION
    Order of tests:
      1. Direct TCP to the remote host (default github.com:443).
      2. If direct fails, probe each local proxy port with a REAL HTTPS request
         through that proxy - an open TCP port alone does not prove the proxy
         can carry traffic.
      3. Report the first proxy that works.

    No git config is touched here. The caller (the agent, following SKILL.md)
    decides what to do with the verdict - normally "set git http.proxy" or
    "unset it and retry".

.PARAMETER TargetHost
    Remote host to test. Default github.com.

.PARAMETER Port
    Remote port to test. Default 443.

.PARAMETER TimeoutSec
    Per-test timeout in seconds. Default 6 - short enough that a dead proxy
    does not stall a git operation for half a minute.

.OUTPUTS
    Plain text, one verdict line first so the caller can parse it cheaply:
      MODE=direct
      MODE=proxy PROXY=http://127.0.0.1:<port>   (with MODEVENDOR=v2rayn|clash)
      MODE=none
    Followed by one human-readable line per test that ran.
    Exit code 0 when a working path was found, 1 when MODE=none.

.EXAMPLE
    pwsh -NoProfile -File Test-GitProxy.ps1
    pwsh -NoProfile -File Test-GitProxy.ps1 -TargetHost gitlab.com
#>
[CmdletBinding()]
param(
    [string]$TargetHost = "github.com",
    [int]$TargetPort = 443,
    [int]$TimeoutSec = 6
)

$ErrorActionPreference = "SilentlyContinue"

# (label, mode, scheme, local port). v2rayN listens socks on 10808 and usually
# an http inbound next to it; Clash exposes one mixed http port on 7890.
$proxies = @(
    @{ Label = "v2rayN http";  Mode = "v2rayn"; Scheme = "http";   Port = 10809 },
    @{ Label = "v2rayN socks"; Mode = "v2rayn"; Scheme = "socks5"; Port = 10808 },
    @{ Label = "Clash http";   Mode = "clash";  Scheme = "http";   Port = 7890 }
)

function Test-TcpOpen([string]$h, [int]$p) {
    $c = New-Object System.Net.Sockets.TcpClient
    try {
        $task = $c.ConnectAsync($h, $p)
        if (-not $task.Wait([TimeSpan]::FromSeconds($TimeoutSec))) { return $false }
        return $c.Connected
    } catch {
        return $false
    } finally {
        $c.Dispose()
    }
}

function Test-ProxyFetch([string]$proxyUrl, [string]$url) {
    # The proxy may have the port open but be unable to reach the target. A real
    # request is the only honest check.
    try {
        $handler = New-Object System.Net.Http.HttpClientHandler
        $handler.Proxy = New-Object System.Net.WebProxy($proxyUrl)
        $handler.UseProxy = $true
        $client = New-Object System.Net.Http.HttpClient($handler)
        $client.Timeout = [TimeSpan]::FromSeconds($TimeoutSec)
        $resp = $client.GetAsync($url).Result
        $code = [int]$resp.StatusCode
        $resp.Dispose(); $client.Dispose(); $handler.Dispose()
        return @{ Ok = ($code -ge 200 -and $code -lt 500); Code = $code }
    } catch {
        return @{ Ok = $false; Code = -1 }
    }
}

# --- step 1: direct -----------------------------------------------------------
$direct = Test-TcpOpen -h $TargetHost -p $TargetPort
if ($direct) {
    Write-Output "MODE=direct"
    Write-Output "direct TCP ${TargetHost}:${TargetPort} reachable"
    exit 0
}
Write-Output "direct TCP ${TargetHost}:${TargetPort} NOT reachable within ${TimeoutSec}s"

# --- step 2: proxies ----------------------------------------------------------
$target = "https://${TargetHost}:${TargetPort}/"
foreach ($p in $proxies) {
    $portOpen = Test-TcpOpen -h "127.0.0.1" -p $p.Port
    if (-not $portOpen) {
        Write-Output "$($p.Label) 127.0.0.1:$($p.Port) - port closed, skip"
        continue
    }
    $proxyUrl = "$($p.Scheme)://127.0.0.1:$($p.Port)"
    $r = Test-ProxyFetch -proxyUrl $proxyUrl -url $target
    if ($r.Ok) {
        Write-Output "$($p.Label) 127.0.0.1:$($p.Port) - HTTP $($r.Code) through proxy, WORKS"
        Write-Output "MODE=proxy MODEVENDOR=$($p.Mode) PROXY=http://127.0.0.1:$($p.Port)"
        exit 0
    }
    Write-Output "$($p.Label) 127.0.0.1:$($p.Port) - port open but no usable answer (code $($r.Code)), skip"
}

# --- step 3: nothing worked ---------------------------------------------------
Write-Output "MODE=none"
exit 1
