# Net::Async::MCP::Run House Rules

Apply to every task in this distribution unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their discipline from the skills force-loaded
via `briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions. When uncertain, ask rather than guess.
   Present alternatives when ambiguous. Push back when a simpler approach exists. Stop when
   confused; name what's unclear.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative.
3. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code or
   formatting. Match existing style.
4. **Surface conflicts, don't average them** — Contradicting patterns: pick one (more
   recent / more tested), explain why, flag the other. Don't blend.
5. **Read before you write** — Before new code, read the base class
   (`Net::Async::MCP::Server`) and the immediate callers. "Looks orthogonal" is dangerous.
6. **Tests verify intent** — A test that can't fail when the logic changes is wrong.
   Reproduce a bug before fixing it; leave a regression test behind.
7. **Fail loud** — "Done" is wrong if anything was skipped silently. "Tests pass" is wrong
   if any were skipped. Surface uncertainty, don't hide it.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): do NOT touch behavior-relevant
  code yourself — delegate to `net-async-mcp-run-worker`. Your lane: coordinate, inspect,
  plan, review diffs, run tests, manage git, edit non-behavioral docs. Why: only the
  `net-async-mcp-run-*` agents get the full Perl/MCP/IO::Async skill set force-loaded via
  `briefing.skills`; you get no briefing and would touch internals with too little context.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug / test anything under `lib/` or `t/` | `net-async-mcp-run-worker` (default) |
  | Pre-release audit | `net-async-mcp-run-release-checker` |

- **You cannot spawn subagents** (you ARE a `net-async-mcp-run-*` agent): the delegation
  lock does not apply — implement, refactor, debug, and test per these rules.

Behavior-relevant = the `run` tool, command execution and its timeout, tool dispatch,
validation/`allowed_commands`, `MCP::Run::Compress` integration, the public API, error
handling, tests. Pure prose docs and Changes notes are not.

## Project-specific hazards

- **Two tool-dispatch paths; the override wins.** `run` is both registered with a `code`
  ref *and* dispatched by an overridden `call_tool`. The override is the live path — the
  registered `code` ref is never invoked. Wiring a new tool only via `register_tool`'s
  `code` looks right and silently never runs; add it to `call_tool` too. (Detail:
  `net-async-mcp-run-core`.)
- **`allowed_commands` is a filter, not a sandbox.** It checks only the command's first
  token, then runs the whole string through `/bin/sh -c` — so `ls; rm -rf /` passes when
  `ls` is allowed. Real policy is the `validator` coderef. Do not "harden" the token check
  into a sandbox without raising it with the user first.
- **stderr is never captured.** `_execute_command` pipes stdout only and always returns an
  empty stderr; a green suite does not prove stderr behaviour. Treat this as a known scope
  gap, not a bug to silently fix.

## Release — never without permission

`dzil build` / `dzil test` are fine anytime. `dzil release` and any CPAN upload are
STRICTLY forbidden without the maintainer's explicit go-ahead — even if a plan or checklist
lists "release" as the next step. For anything heading toward release: stop and ask.

## Public issues — never act without instruction

If this repo has a public tracker, it carries real humans' reports under the maintainer's
account — it is not an AI work queue. **Never act on a public issue on your own initiative,
not even to read it.** No listing, viewing, commenting, editing, closing, or creating unless
the user explicitly says to handle a specific issue.

## Coordination — karr board

Internal AI-to-AI coordination uses `karr` (git-native kanban; state in `refs/karr/*`),
skill hardlinked at `.claude/skills/kanban-issues-karr-cli/`. This is a small,
single-module repo with typically one agent at a time, so reach for the board when work
spans multiple sessions or subagents, not for routine single-session tasks. A board is
initialized here (`karr board`) — do not run `karr init`. When fanning work out, serialize
board mutations (`karr move`/`handoff`/`sync`): parallel implementation is fine, but
concurrent board writes have OOM-rebooted a host — collect results, then loop the writes
sequentially. Full command surface: skill `kanban-issues-karr-cli`.

## Perl / MCP / IO::Async specifics — reference, don't restate

Module loading, async idioms, MCP protocol handling, dependency pinning and house style
live in skills `getty-perl-core`, `perl-io-async-future`, `perl-mcp`,
`perl-release-dist-ini` and `net-async-mcp-run-core` (force-loaded for
`net-async-mcp-run-*` agents). Do not duplicate that content here.
