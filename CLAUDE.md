# Net::Async::MCP::Run

Async MCP (Model Context Protocol) **server** that adds a `run` command-execution tool to
`Net::Async::MCP::Server`, built on `IO::Async` and `Future::AsyncAwait`. A single module,
`lib/Net/Async/MCP/Run.pm`. Released to CPAN as `Net-Async-MCP-Run`, built and released with
`Dist::Zilla` via `[@Author::GETTY]`.

The architecture — the server-subclass shape, the two tool-dispatch paths, the `/bin/sh`
execution model with its timeout and stdout-only capture, the `allowed_commands` gate that
is a filter not a sandbox, the `MCP::Run::Compress` reuse, and the per-file `$VERSION`
style — lives in skill `net-async-mcp-run-core`, not here. Engineering discipline, the
release-permission rule and the public-issues rule live in
`.claude/rules/net-async-mcp-run-rules.md`.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself — the
principle and the lane boundaries are in `.claude/rules/net-async-mcp-run-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug / test anything under `lib/` or `t/` | `net-async-mcp-run-worker` (default) |
| Pre-release audit | `net-async-mcp-run-release-checker` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main agent
delegates rather than loading them. Skill sources live under `.claude/skills/` —
`getty-perl-core`, `getty-perl-release-author-getty`, `perl-release-dist-ini`,
`perl-io-async-future` and `perl-mcp` are hardlinked shared skills, `kanban-issues-karr-cli`
from the karr source; `net-async-mcp-run-core` is owned by this repo.

Internal AI-to-AI work is coordinated on the repo's `karr` board (`karr board`). Any public
tracker is for real users — never act on one without explicit instruction (see the rules
file).
