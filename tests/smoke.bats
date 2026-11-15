load test_helper

setup() {
  setup_yazi viewer
  cat >"$YAZI_CONFIG_HOME/yazi.toml" <<'EOF'
[plugin]
prepend_previewers = [
  { mime = "image/{jpeg,png,gif,webp,bmp,tiff}", run = "viewer image --max_up=3 --fill=0.8" },
]
EOF
  magick -size 40x30 xc:red "$WORK/a.png"
  magick -size 30x40 xc:blue "$WORK/b.png"
}

teardown() { stop_yazi; }

@test "an image is previewed without an error of Lua" {
  start_yazi
  send_keys j
  assert_healthy
}

@test "the options in the rule do not break the start" {
  start_yazi
  assert_healthy
  screen | grep -q "a.png"
}
