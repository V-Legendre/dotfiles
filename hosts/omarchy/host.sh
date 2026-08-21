#!/usr/bin/env bash
# Omarchy (Arch + Hyprland) host manifest. Sourced by install.sh with HOST_DIR
# pointing here.
#
# This machine only takes the shared layer: zsh, powerlevel10k and the global
# Zed config. Add hosts/omarchy/{home,config}/ trees here as the setup grows —
# host_install() picks them up automatically.

HOST_INSTALL_PROJECTS=0

host_install() {
  head_ "Home directory configs (omarchy)"
  link_tree "$HOST_DIR/home" "$HOME"

  head_ "~/.config (omarchy)"
  link_tree "$HOST_DIR/config" "$HOME/.config"
}
