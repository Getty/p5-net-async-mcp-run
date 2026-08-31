---
name: net-async-mcp-run-core
description: "Load before editing Net::Async::MCP::Run — the async MCP server that adds a `run` command-execution tool to Net::Async::MCP::Server: how it subclasses the base server, the two competing tool-dispatch paths and which one wins, the /bin/sh command-execution model with its timeout and captured-stdout-only reality, the allowed_commands gate that is a filter not a sandbox, and the MCP::Run::Compress reuse."
---

# Net::Async::MCP::Run — core

An asynchronous MCP **server** that exposes one tool, `run`, for command execution.
It is a subclass — `use parent 'Net::Async::MCP::Server'` — that adds the tool and its
async execution machinery to the base server; it is **not** a transport and never speaks
the wire protocol itself. Built on `IO::Async` and `Future::AsyncAwait`. The whole
distribution is a single module, `lib/Net/Async/MCP/Run.pm`. No `Moo` here (the base is a
plain `IO::Async::Notifier`) — do not introduce it.

## Where it sits — server subclass, not a transport

```
Net::Async::MCP::Server            (base dist: p5-net-async-mcp-server)
  └─ Net::Async::MCP::Run          (this dist: adds the `run` tool)
        ▲ wrapped by, never contains ▲
Net::Async::MCP::Server::Transport::Stdio   (base dist: the wire boundary)
```

`Run` holds tool logic and command execution. A **transport** object wraps a server
instance and drives the JSON-RPC/wire I/O — `Run` never encodes/decodes the wire. Keep
that boundary: server logic that reaches into transport framing is wrong. `run_stdio`
(class method) is only a convenience: `new` the server, add it to a fresh `IO::Async::Loop`,
hand it to `Net::Async::MCP::Server::Transport::Stdio->handle_requests`.

## The two tool-dispatch paths — the override wins, the `code` ref is dead

This is the seam that surprises people. The `run` tool is wired **twice**:

1. `_register_run_tool` registers it on the base with `code => sub { $self->_handle_run(@_) }`.
   The base's own `call_tool` would invoke that `code` ref as `$code->($arguments)`.
2. `Run` also **overrides `call_tool` entirely**: `run` → `await $self->_handle_run($name, $arguments)`,
   anything else → `die "Unknown tool: $name"`.

Because the override never falls through to the base for `run`, the registered `code` ref
is **never called** — the override is the live path. (The registration still matters for
`list_tools`, which reads the registered tool's `inputSchema`.) When adding a second tool,
add it to the `call_tool` override **and** register it; do not assume the `code` ref runs.
The two-path redundancy is existing structure — reconcile it knowingly, don't half-migrate.

## Command execution model — read before touching `_execute_command`

- Runs through **`/bin/sh -c`**. `working_directory` is applied as a shell prefix
  `cd '<escaped>' && <command>` (single-quotes escaped), **not** via IO::Async's own
  process `chdir`. Per-call `working_directory` overrides the server default.
- **stdout is captured; stderr is not.** The `IO::Async::Process` spec pipes only stdout;
  `_execute_command` always returns `stderr => ''`. A caller asking "why is stderr empty"
  is meeting a **known gap**, not a bug — flag it before "fixing".
- `exit_code = $status >> 8`. On success `stdout` is `chomp`ed.
- **Timeout**: `IO::Async::Timer::Countdown` fires `$process->kill('TERM')` (single
  process, not the group), and the result becomes `exit_code => 124`, empty stdout, an
  `error` string. Completion is awaited on a `$self->loop->new_future` resolved in
  `on_finish`. Child process + timer are added via `add_child` and removed after.

## `allowed_commands` is a coarse gate, not a sandbox

`_validate_command` checks only the **first whitespace token** of the command against
`allowed_commands`. Because execution then goes through `/bin/sh -c`, the whitelist does
**not** confine the shell: with `ls` allowed, `ls; rm -rf /` passes. This is a deliberate
scope decision — real policy is the caller's job via the `validator` coderef (called with
`($command, $working_directory)`; return a true value to allow, a string to reject with
that message). Do not silently "harden" the token check into a sandbox; raise it with the
user first.

`_validate_command`'s return convention is a sentinel: the string **`'1'`** means allowed,
any other string is the rejection message; the caller compares `ne '1'`. Keep that shape
if you touch it.

## MCP::Run::Compress reuse — the only MCP::Run-family dependency

`Run` uses **`MCP::Run::Compress`** (from the `MCP::Run` distribution — `cpanfile` requires
`MCP::Run`), never `MCP::Run` itself. It is used for two distinct things:

- **`transform_command`** — rewrites the command *before* execution (e.g. Co-Authored-By
  injection for `git commit`). Runs unconditionally **unless** `$ENV{MCP_RUN_COMPRESS_NO_CO_AUTHORED}`
  is true. This is a global env kill-switch, independent of the per-call `compress` flag.
- **`compress`** — post-processes stdout/stderr *after* execution, only when the `compress`
  attribute/argument is on.

Keep these two roles separate: command transform is always-on-by-default input rewriting;
compression is opt-in output rewriting.

## Attributes and their `configure` seam

`allowed_commands` (ArrayRef, default `[]`), `working_directory`, `timeout` (default 30),
`compress` (default 0), `validator` (coderef), `name`. They are handled in an overridden
`configure` that `delete`s each known key before calling `SUPER::configure`, and defaulted
in `_init`. `_build_capabilities` currently returns `{ tools => {} }` — identical to the
base; the override is redundant today, not a signal that capabilities are populated.

## Version style — standard per-file `$VERSION`

This dist uses the **default** `[@Author::GETTY]` convention: `our $VERSION` lives in the
module (`lib/Net/Async/MCP/Run.pm`). There is **no** `version_finder = :MainModule`
override in `dist.ini` (unlike the sibling `Net::Async::MCP`). With a single module the
distinction is moot — but do not import that sibling's `:MainModule` exception here.

The repo `$VERSION` is the *next unreleased* number, never copied back from CPAN. The
Getty-authored deps (`Net::Async::MCP::Server`, the `MCP::Run` distribution) are released
together with this one — per the house rule, a dep's CPAN release-stand is never itself a
blocker and never a reason to lower a `cpanfile` entry.
