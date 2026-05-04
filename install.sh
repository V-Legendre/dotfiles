#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECTS_DIR="$HOME/Documents/Projects"

if [ ! -d "$PROJECTS_DIR" ]; then
  echo "Error: $PROJECTS_DIR does not exist. Aborting." >&2
  exit 1
fi

link_file() {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ]; then
    local current_target
    current_target="$(readlink "$dest")"
    if [ "$current_target" = "$src" ]; then
      echo "  ok: $dest"
      return
    fi
    echo "  updating: $dest (was → $current_target)"
    rm "$dest"
  elif [ -e "$dest" ]; then
    echo "  backing up: $dest → ${dest}.bak"
    mv "$dest" "${dest}.bak"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  echo "  linked: $dest → $src"
}

echo "==> Home directory configs"
for f in "$DOTFILES_DIR"/home/.*; do
  [ -f "$f" ] || continue
  link_file "$f" "$HOME/$(basename "$f")"
done

echo "==> ~/.local/bin scripts"
for f in "$DOTFILES_DIR"/home/.local/bin/*; do
  [ -f "$f" ] || continue
  link_file "$f" "$HOME/.local/bin/$(basename "$f")"
done

echo "==> ~/.config"
find "$DOTFILES_DIR/config" -type f | while read -r f; do
  rel="${f#"$DOTFILES_DIR"/config/}"
  link_file "$f" "$HOME/.config/$rel"
done

echo "==> Mistral Vibe config"
if [ -f "$DOTFILES_DIR/config/vibe/config.toml" ]; then
  mkdir -p "$HOME/.vibe"
  link_file "$DOTFILES_DIR/config/vibe/config.toml" "$HOME/.vibe/config.toml"
fi

echo "==> AWS config"
if [ -f "$DOTFILES_DIR/aws/config" ]; then
  link_file "$DOTFILES_DIR/aws/config" "$HOME/.aws/config"
fi

echo "==> Per-project .zed configs"
for project_dir in "$DOTFILES_DIR"/projects/*/; do
  project="$(basename "$project_dir")"
  target_base="$PROJECTS_DIR/$project"
  if [ ! -d "$target_base" ]; then
    echo "  skipping $project (project dir not found)"
    continue
  fi
  find "$project_dir" -type f | while read -r f; do
    rel="${f#"$project_dir"}"
    link_file "$f" "$target_base/$rel"
  done
done

echo "Done!"
