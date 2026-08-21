# dotfiles

Config files managed via symlinks, shared across several machines. Files live in
this repo; `install.sh` detects the host and creates symlinks at the expected
locations.

## Layout

```
shared/          installed on every host
  home/          → ~/                      (.zshrc, .p10k.zsh)
  config/        → ~/.config/              (zed settings & tasks)
  zed/           merged into ~/.config/zed/keymap.json
  zshrc.d/       → ~/.zshrc.d/             (10-*: shared shell config)
hosts/<host>/    installed only on that host
  host.sh        manifest: what this host installs
  home/          → ~/
  config/        → ~/.config/
  zed/           keymap overlay merged on top of shared/zed/keymap.base.json
  zshrc.d/       → ~/.zshrc.d/             (50-*: host-specific shell config)
  aws/config     → ~/.aws/config           (macOS only)
projects/        → ~/Documents/Projects/<name>/   (opt-in per host)
lib/common.sh    symlink / merge helpers
```

## Hosts

| Host | Gets |
|---|---|
| `macos` | everything: shared layer + aerospace, simple-bar, alacritty, borders, Mistral Vibe, AWS config, per-project `.zed` configs |
| `omarchy` | shared layer only: zsh + powerlevel10k + global Zed config |

Detection: `Darwin` → `macos`; Linux with `~/.local/share/omarchy` → `omarchy`.
Override with `./install.sh --host <name>` or `DOTFILES_HOST=<name>`.

## Setup

```sh
git clone git@github.com:V-Legendre/dotfiles.git
cd dotfiles
./install.sh --dry-run   # preview
./install.sh
```

Existing files are backed up as `.bak` before being replaced with symlinks.
Safe to re-run.

Prerequisites on a fresh machine: [oh-my-zsh](https://ohmyz.sh),
[powerlevel10k](https://github.com/romkatv/powerlevel10k) and the
`zsh-nvm` / `zsh-syntax-highlighting` plugins. `install.sh` warns if they are missing.

## How the shared layer stays portable

**Shell** — `shared/home/.zshrc` holds no machine-specific path. It sources
`~/.zshrc.d/*.zsh` in lexical order:

- `10-*`, `20-*` — shared (PATH, aliases, tool activation, all guarded by
  `command -v` style checks so a missing tool is never an error)
- `50-*` — host-specific (Homebrew, Docker Desktop, Tailscale… on macOS)
- `90-*` — anything you drop in `~/.zshrc.d/` by hand stays untracked and loads last

**Zed keymap** — the bindings are modifier-dependent (`cmd-` on macOS, `ctrl-`
on Linux), and Zed only reads a single `keymap.json`. So that one file is
*generated*: `install.sh` concatenates `shared/zed/keymap.base.json`
(OS-neutral bindings) with `hosts/<host>/zed/keymap.json`. Edit the sources,
never `~/.config/zed/keymap.json`. `settings.json` and `tasks.json` are plain
shared symlinks.

The merge is textual, so both fragments must keep their opening `[` and closing
`]` alone on their own lines.

## Adding a machine

1. `mkdir -p hosts/<name>/{zed,zshrc.d}`
2. Copy `hosts/omarchy/host.sh` and adjust it
3. Add `hosts/<name>/zed/keymap.json` (start from the closest existing overlay)
4. Teach `detect_host()` in `install.sh` about it, or always pass `--host <name>`

## Adding a new project's .zed config

1. Copy the files into `projects/<name>/.zed/`
2. Re-run `./install.sh`
