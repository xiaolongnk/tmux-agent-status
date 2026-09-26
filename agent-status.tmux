#!/usr/bin/env bash
# tmux-agent-status — TPM entry point.
#
#   set -g @plugin 'xiaolongnk/tmux-agent-status'
#
# Replaces the placeholder #{agent_status} in status-left / status-right with the live
# fragment ("⬡ Claude 2 ●1  ◆ Codex 1"), and binds the jump keys. Options (set before
# `run '~/.tmux/plugins/tpm/tpm'`):
#
#   set -g @agent_status_jump_waiting 'Enter'   # next pane waiting for you   ('' = don't bind)
#   set -g @agent_status_jump_any     'Tab'     # cycle every agent pane
#   set -g @agent_status_jump_claude  'a'
#   set -g @agent_status_jump_codex   'e'
#   set -g @agent_status_jump_gemini  'g'
#   set -g @agent_status_jump_cursor  ''        # unbound by default
#
# Without a placeholder the fragment is prepended to status-right, so the plugin works
# with a stock config too.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAG="#($HERE/scripts/agent-status.sh)"

opt() { tmux show-option -gqv "$1"; }
val() { local v; v="$(opt "$1")"; if [ -n "$v" ]; then printf '%s' "$v"; else printf '%s' "$2"; fi; }

placed=false
for side in status-left status-right; do
  cur="$(tmux show-option -gqv "$side")"
  case "$cur" in
    *'#{agent_status}'*)
      tmux set-option -gq "$side" "${cur//\#\{agent_status\}/$FRAG}"
      placed=true ;;
  esac
done
if ! $placed; then
  cur="$(tmux show-option -gqv status-right)"
  case "$cur" in *"agent-status.sh"*) ;; *) tmux set-option -gq status-right "$FRAG$cur" ;; esac
fi

bind_jump() { # bind_jump <option> <default-key> <agent>
  local key; key="$(val "$1" "$2")"
  if [ -n "$key" ]; then tmux bind-key "$key" run-shell "$HERE/scripts/agent-jump.sh $3"; fi
}
bind_jump @agent_status_jump_waiting Enter waiting
bind_jump @agent_status_jump_any     Tab   any
bind_jump @agent_status_jump_claude  a     claude
bind_jump @agent_status_jump_codex   e     codex
bind_jump @agent_status_jump_gemini  g     gemini
bind_jump @agent_status_jump_cursor  ''    cursor
