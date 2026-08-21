#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/common.sh
source "$DOTFILES_DIR/lib/common.sh"

usage() {
  cat <<EOF
Usage: ./install.sh [--host <name>] [--dry-run]

  --host <name>   Force a host profile (a directory under hosts/).
                  Defaults to \$DOTFILES_HOST, else auto-detected.
  --dry-run       Print what would happen without touching the filesystem.

Available hosts: $(ls "$DOTFILES_DIR/hosts" | tr '\n' ' ')
EOF
}

HOST="${DOTFILES_HOST:-}"
while [ $# -gt 0 ]; do
  case "$1" in
    --host) HOST="${2:-}"; [ -n "$HOST" ] || die "--host needs a value"; shift 2 ;;
    --host=*) HOST="${1#*=}"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; die "unknown argument: $1" ;;
  esac
done

detect_host() {
  case "$(uname -s)" in
    Darwin) echo macos ;;
    Linux)
      if [ -d "$HOME/.local/share/omarchy" ] || [ -n "${OMARCHY_PATH:-}" ]; then
        echo omarchy
      else
        echo ""
      fi
      ;;
    *) echo "" ;;
  esac
}

[ -n "$HOST" ] || HOST="$(detect_host)"
[ -n "$HOST" ] || die "could not detect host. Re-run with --host <$(ls "$DOTFILES_DIR/hosts" | paste -sd'|' -)>"

HOST_DIR="$DOTFILES_DIR/hosts/$HOST"
[ -d "$HOST_DIR" ] || die "unknown host '$HOST' (no hosts/$HOST directory)"

HOST_INSTALL_PROJECTS=0
HOST_PROJECTS_DIR=""
# shellcheck source=/dev/null
source "$HOST_DIR/host.sh"

echo "dotfiles: $DOTFILES_DIR"
echo "host:     $HOST"
[ "$DRY_RUN" = "1" ] && echo "mode:     dry-run (nothing will be written)"

# --- shared layer ----------------------------------------------------------

head_ "Home directory configs (shared)"
link_tree "$DOTFILES_DIR/shared/home" "$HOME"

head_ "~/.config (shared)"
link_tree "$DOTFILES_DIR/shared/config" "$HOME/.config"

head_ "Zsh drop-ins (~/.zshrc.d)"
run mkdir -p "$HOME/.zshrc.d"
link_tree "$DOTFILES_DIR/shared/zshrc.d" "$HOME/.zshrc.d"
link_tree "$HOST_DIR/zshrc.d" "$HOME/.zshrc.d"
prune_links "$HOME/.zshrc.d" "$DOTFILES_DIR"

head_ "Zed keymap (shared base + $HOST overlay)"
merge_json_arrays "$HOME/.config/zed/keymap.json" \
  "$DOTFILES_DIR/shared/zed/keymap.base.json" \
  "$HOST_DIR/zed/keymap.json"

# --- host layer ------------------------------------------------------------

host_install

# --- projects --------------------------------------------------------------

if [ "$HOST_INSTALL_PROJECTS" = "1" ]; then
  head_ "Per-project .zed configs"
  if [ ! -d "$HOST_PROJECTS_DIR" ]; then
    warn "$HOST_PROJECTS_DIR does not exist — skipping project configs"
  else
    for project_dir in "$DOTFILES_DIR"/projects/*/; do
      project="$(basename "$project_dir")"
      target_base="$HOST_PROJECTS_DIR/$project"
      if [ ! -d "$target_base" ]; then
        log "skipping $project (project dir not found)"
        continue
      fi
      link_tree "${project_dir%/}" "$target_base"
    done
  fi
fi

# --- sanity checks ---------------------------------------------------------

head_ "Checks"
[ -d "$HOME/.oh-my-zsh" ] || warn "oh-my-zsh is not installed — the shared .zshrc expects it"
[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ] \
  || warn "powerlevel10k is not installed in oh-my-zsh custom themes"

echo
echo "Done!"
