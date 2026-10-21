# Net::Async::MCP::Run House Rules

Apply to every task in this distribution unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Skill content is never restated
here: the skills are the source, the agents get them force-loaded via `briefing.skills`.
Module loading, async idioms, MCP protocol handling, dependency pinning and house style
live in the skills `getty-perl-core`, `perl-io-async-future`, `perl-mcp`,
`perl-release-dist-ini` and `net-async-mcp-run-core` — don't repeat that content here.

## Engineering discipline

1. **Think before coding** — State assumptions, ask rather than guess, present alternatives
   when ambiguous, push back when a simpler approach exists, stop when confused.
2. **Simplicity first** — Minimum code that solves the problem, nothing speculative.
3. **Surgical changes** — Touch only what you must; don't "improve" adjacent code or
   formatting. Match existing style.
4. **Surface conflicts, don't average them** — Pick one (more recent / more tested),
   explain why, flag the other; don't blend.
5. **Read before you write** — Before new code, read the base class
   (`Net::Async::MCP::Server`) and the immediate callers. "Looks orthogonal" is dangerous.
6. **Tests verify intent** — A test that can't fail when the logic changes is wrong;
   reproduce a bug before fixing it, leave a regression test behind.
7. **Fail loud** — "Done" is wrong if anything was skipped silently; surface uncertainty.

## Delegation

If you can spawn subagents (orchestrating main agent): do NOT touch behavior-relevant code
yourself — delegate to `net-async-mcp-run-worker`. Your lane: coordinate, inspect, plan,
review diffs, run tests, edit non-behavioral docs. You get no briefing.

| Task | Agent |
|---|---|
| Implement / refactor / debug / test anything under `lib/` or `t/` | `net-async-mcp-run-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `net-async-mcp-run-release-manager` |

If you ARE a `net-async-mcp-run-*` agent, the delegation lock does not apply — implement,
refactor, debug and test per these rules.

Behavior-relevant = the `run` tool, command execution and its timeout, tool dispatch,
validation/`allowed_commands`, `MCP::Run::Compress` integration, the public API, error
handling and the tests. Pure prose docs and Changes notes are not.

**Only `net-async-mcp-run-release-manager` commits.** A worker leaves a commit-ready tree
and hands its card to `review`; you then dispatch the release-manager to cut the commit and
close the card.

## Project-specific hazards

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

## Coordination — karr board

Internal AI-to-AI coordination uses `karr` (git-native kanban; state in `refs/karr/*`),
skill hardlinked at `.claude/skills/kanban-issues-karr-coordination/`. A board is
initialized here (`karr board`) — do not run `karr init`. Small single-module repo: reach
for the board when work spans multiple sessions or subagents, not for routine tasks.

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail · `karr create
  "Title" --priority high --tags a,b --body '…'` — new ticket
- `karr edit ID -a "note"` · `--claim NAME` · `--block "why"` — update · `karr move ID
  in-progress --claim NAME` — start · `karr handoff ID --claim NAME --note "…"` — to review

**Serialize board mutations when fanning out.** Collect the results, then loop the
`karr move`/`handoff`/`sync` calls sequentially — parallel implementation is fine, but
concurrent board writes have OOM-rebooted a host. Surface: skill `kanban-issues-karr-coordination`.

## Release — never without permission

`dzil build` / `dzil test` are fine anytime. `dzil release` and any CPAN upload are
STRICTLY forbidden without the maintainer's explicit go-ahead — even if a plan or checklist
lists "release" as the next step: stop and ask. No push, no tag.

## Public issues — never act without instruction

If this repo has a public tracker, it carries real humans' reports under the maintainer's
account — it is not an AI work queue. **Never act on a public issue on your own initiative,
not even to read it.** No listing, viewing, commenting, editing, closing, or creating unless
the user explicitly says to handle a specific issue.
