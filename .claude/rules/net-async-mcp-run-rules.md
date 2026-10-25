# Net::Async::MCP::Run House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Async MCP server with command execution — a `run` tool on top of `Net::Async::MCP::Server`,
one module. Read first: the base class (`Net::Async::MCP::Server`) and the immediate callers.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug / test anything under `lib/` or `t/` | `net-async-mcp-run-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `net-async-mcp-run-release-manager` |
| Read-only research, audit, gap analysis | `net-async-mcp-run-worker` ("read-only, change nothing") |

Behavior-relevant = the `run` tool, command execution and its timeout, tool dispatch,
validation/`allowed_commands`, `MCP::Run::Compress` integration, the public API, error
handling and the tests. Pure prose docs and Changes notes are not.

## Deviations from the house rules

- **karr is rarely needed here.** Small single-module repo: reach for the board when work
  spans multiple sessions or subagents, not for routine tasks. The board is already
  initialized (`karr board`) — never run `karr init`.

## Hazards

- **Two tool-dispatch paths; the override wins.** `run` is both registered with a `code`
  ref *and* dispatched by an overridden `call_tool`; the override is the live path, the
  registered `code` ref is never invoked. A new tool wired only via `register_tool`'s
  `code` silently never runs — add it to `call_tool` too. Detail: `net-async-mcp-run-core`.
- **`allowed_commands` is a filter, not a sandbox.** It checks only the command's first
  token, then runs the whole string through `/bin/sh -c` — so `ls; rm -rf /` passes when
  `ls` is allowed. Real policy is the `validator` coderef. Do not "harden" the token check
  into a sandbox without raising it with the user first.
- **stderr is never captured.** `_execute_command` pipes stdout only and always returns an
  empty stderr; a green suite does not prove stderr behaviour. Known scope gap, not a bug
  to silently fix.

## Perl / async / MCP specifics — reference, don't restate

Module loading, async idioms, MCP protocol handling, dependency pinning and house style live
in skills `getty-perl-core`, `perl-io-async-future`, `perl-mcp`, `perl-release-dist-ini` and
`net-async-mcp-run-core` (force-loaded for `net-async-mcp-run-*` agents).
