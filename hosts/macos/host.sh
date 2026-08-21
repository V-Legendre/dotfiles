#!/usr/bin/env bash
# macOS host manifest. Sourced by install.sh with HOST_DIR pointing here.
#
# Everything in this repo lands on this machine: the shared configs plus the
# macOS-only window manager, terminal, AWS and per-project Zed configs.

# Link per-project .zed configs from projects/ into ~/Documents/Projects/<name>/
HOST_INSTALL_PROJECTS=1
HOST_PROJECTS_DIR="$HOME/Documents/Projects"

host_install() {
  head_ "Home directory configs (macOS)"
  link_tree "$HOST_DIR/home" "$HOME"

  head_ "~/.config (macOS)"
  link_tree "$HOST_DIR/config" "$HOME/.config"

  head_ "Mistral Vibe config"
  if [ -f "$HOST_DIR/config/vibe/config.toml" ]; then
    link_file "$HOST_DIR/config/vibe/config.toml" "$HOME/.vibe/config.toml"
  fi

  head_ "AWS config"
  if [ -f "$HOST_DIR/aws/config" ]; then
    link_file "$HOST_DIR/aws/config" "$HOME/.aws/config"
  fi
}
