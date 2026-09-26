# tmux-agent-status

**See which of your AI coding agents are waiting for you — and jump there.**

A tmux plugin for people who run several Claude Code / Codex / Cursor / Gemini CLI panes at
once. The status bar counts the agent panes and marks the ones that need you; one key takes
you to the next one.

```
 agents  1:agents                             ⬡ Claude 2 ●1  ◆ Codex 2 ●1   14:02  host
```

`⬡ Claude 2 ●1` = two Claude Code panes, one of them idle or asking for approval.

![demo](https://raw.githubusercontent.com/xiaolongnk/fleetmux/main/docs/assets/fleetmux-demo.gif)

## Install (TPM)

```tmux
set -g @plugin 'xiaolongnk/tmux-agent-status'
```

Then `prefix + I`. Put `#{agent_status}` wherever you want the fragment:

```tmux
set -g status-right '#{agent_status} %H:%M #h'
```

(No placeholder? It's prepended to `status-right` automatically.)

Manual install: clone this repo and add `run-shell /path/to/agent-status.tmux` to your config.

## Keys

| Key (after prefix) | Action | Option |
|---|---|---|
| `Enter` | next agent pane **waiting for you** (idle or approval prompt) | `@agent_status_jump_waiting` |
| `Tab` | cycle every agent pane | `@agent_status_jump_any` |
| `a` / `e` / `g` | cycle Claude / Codex / Gemini panes | `@agent_status_jump_claude` … |
| — | Cursor: `set -g @agent_status_jump_cursor 'u'` | `@agent_status_jump_cursor` |

Set an option to `''` to leave a key alone. Each press moves to the *next* matching pane
after the current one, across windows and sessions, wrapping around.

## How it works

**Which panes are agents** — by the pane's running command (`#{pane_current_command}`):
`claude`, `codex`, `cursor-agent`, `gemini`. Not by title: Claude Code titles its pane with the
conversation topic, Codex with the task, so on a real server with 12 Claude and 16 Codex panes
only one title contained the word "claude". A pane running `node`/`python` is classified by
its title as a fallback (Gemini CLI is a Node program).

**What state a pane is in** — from the last lines of its screen (`tmux capture-pane`), since
tmux has no per-pane activity clock and every agent prints the same tells:

| Screen shows | State |
|---|---|
| `esc to interrupt`, `esc to cancel`, a spinner `⠇` | **busy** — leave it |
| `Do you want to proceed`, `❯ 1. Yes`, `(y/n)`, `Allow once/always` (at line start) | **attention** — asking you |
| neither | **idle** — done, waiting for your next message |

`●N` counts attention + idle. Polling 29 panes takes ~0.4 s; the bar refreshes on tmux's
`status-interval` (5 s by default).

```sh
~/.tmux/plugins/tmux-agent-status/scripts/agent-status.sh --list | column -t -s $'\t'
# target        agent   state      title
# work:1.1      claude  busy       ✳ Refactor auth middleware
# work:1.2      codex   idle       Write quickstart docs
# work:2.1      claude  attention  ✳ Fix flaky build
```

## Adding an agent

One `case` arm in `classify()` in `scripts/agent-status.sh` (command name → agent), plus a
counter and a `frag` line at the bottom. `test/agent-status.sh` shows how to assert it
against a fixture (`FLEETMUX_PANES` replaces the tmux queries).

## Part of fleetmux

This plugin is the status bar from [fleetmux](https://github.com/xiaolongnk/fleetmux), the
agent-native tmux distribution — one command installs tmux + this + Starship + a Nerd Font,
with `fleetmux-start claude codex` to launch agents and `fleetmux-doctor` to check the setup.
Use the plugin alone if you already have a tmux config you like.

Requires tmux ≥ 3.0 and bash. MIT.
