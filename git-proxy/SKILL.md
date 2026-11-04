---
name: git-proxy
description: Before any git network operation (clone, fetch, pull, push, ls-remote), decide whether the remote is reachable directly or needs the v2rayN / Clash local proxy, and configure git to use the one that works.
---

# Git Proxy

Use this skill before ANY git command that touches the network: `clone`,
`fetch`, `pull`, `push`, `ls-remote`, `remote -v update`. Also use it when a git
command is already failing with a timeout, `Could not resolve host`, `Connection
timed out`, or `Failed to connect`.

The machine may be behind a firewall where github.com (or another remote) is only
reachable through a local proxy - v2rayN or Clash. An open local port does NOT
mean the proxy works, so the check is a real request through the proxy, not a TCP
ping.

## Workflow

1. Run the probe script. It prints a verdict line first, then one line per test
   it ran:

```sh
pwsh -NoProfile -File <skill-dir>/scripts/Test-GitProxy.ps1
```

Parse the first line only:

| First line | Meaning |
| --- | --- |
| `MODE=direct` | Remote is reachable directly. |
| `MODE=proxy` with `MODEVENDOR=v2rayn` or `clash`, and `PROXY=http://127.0.0.1:<port>` | Use that proxy. |
| `MODE=none` | Neither direct nor any proxy works. |

Pass `-TargetHost gitlab.com` (or the actual remote host) when the remote is not
github. The script is read-only: it never touches git config. Exit code is 0 when
a working path was found, 1 on `MODE=none`.

2. Act on the verdict:

| Verdict | Do this |
| --- | --- |
| `MODE=direct` | Run the git command as-is. No proxy config. |
| `MODE=proxy` | Use the reported `PROXY=http://127.0.0.1:<port>` one of two ways, below. |
| `MODE=none` | Tell the user; do NOT silently retry. Offer to re-run once the proxy client is started. |

3. Using the winning proxy for one command only (preferred - leaves no lasting
   config):

```sh
git -c http.proxy=http://127.0.0.1:<port> -c https.proxy=http://127.0.0.1:<port> clone <url>
```

4. To make it stick for the repo (only if the user asks for it):

```sh
git config http.proxy  http://127.0.0.1:<port>
git config https.proxy http://127.0.0.1:<port>
```

To undo later:

```sh
git config --unset http.proxy
git config --unset https.proxy
```

## Notes

- The proxy port the script reports is the port that actually answered, which
  may be v2rayN's http inbound (10809) or socks inbound (10808) or Clash's
  mixed port (7890). Git accepts an http URL for both http and socks inbounds
  on Windows; if a socks inbound misbehaves with `-c http.proxy`, switch git to
  the socks URL explicitly (`socks5://127.0.0.1:10808`).
- If the remote is a private host on the LAN, prefer direct even when a proxy is
  running - routing LAN traffic through the proxy is usually wrong. Pass the
  actual host with `-TargetHost` so the probe tests the right thing.
- A short per-test timeout keeps a dead proxy from stalling the git command.
- Re-run the probe if the git command still fails after configuring the proxy:
  the proxy client may have been restarted on a different port.
