# Helpers of the smoke tests: Yazi runs in a detached tmux session with a configuration of its own,
# which has the plugin from this repo, and the tests read what is on its screen.

setup_yazi() {
  PLUGIN="$1"
  export YAZI_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
  export TERM=xterm-256color
  WORK="$BATS_TEST_TMPDIR/work"
  SESSION="smoke-$$-$BATS_TEST_NUMBER"
  mkdir -p "$YAZI_CONFIG_HOME/plugins/$PLUGIN.yazi" "$WORK"
  cp "$BATS_TEST_DIRNAME/../main.lua" "$YAZI_CONFIG_HOME/plugins/$PLUGIN.yazi/main.lua"
}

start_yazi() {
  tmux -L "$SESSION" new-session -d -s "$SESSION" -x 160 -y 40 \
    "yazi '$WORK' 2>'$BATS_TEST_TMPDIR/stderr'; echo exit=\$? >'$BATS_TEST_TMPDIR/exit'; sleep 30"
  sleep 3
}

send_keys() {
  tmux -L "$SESSION" send-keys -t "$SESSION" "$@"
  sleep 1.5
}

screen() {
  tmux -L "$SESSION" capture-pane -t "$SESSION" -p
}

stop_yazi() {
  tmux -L "$SESSION" kill-server 2>/dev/null || true
}

# Yazi runs and shows no error of Lua, and no use of a deprecated API
assert_healthy() {
  [ ! -f "$BATS_TEST_TMPDIR/exit" ]
  [ ! -s "$BATS_TEST_TMPDIR/stderr" ]
  ! screen | grep -q -E "Lua error|Deprecated API|Failed to load plugin"
}
