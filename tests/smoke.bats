load test_helper

setup() {
  setup_yazi viewer
  echo 'require("viewer"):setup { max_up = 3, fill = 0.8 }' >"$YAZI_CONFIG_HOME/init.lua"
  cat >"$YAZI_CONFIG_HOME/yazi.toml" <<'EOF'
[plugin]
prepend_previewers = [
  { mime = "image/{jpeg,png,gif,webp,bmp,tiff}", run = "viewer image" },
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

@test "the setup of the defaults does not break the start" {
  start_yazi
  assert_healthy
  screen | grep -q "a.png"
}
