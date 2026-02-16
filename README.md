# dotfiles

Config files managed via symlinks. Files live in this repo; `install.sh` creates symlinks at the expected locations.

## What's tracked

| Repo path | Links to |
|---|---|
| `home/.*` | `~/` |
| `config/` | `~/.config/` |
| `aws/config` | `~/.aws/config` |
| `projects/<name>/.zed/` | `~/Documents/Projects/<name>/.zed/` |

## Setup

```sh
git clone git@github.com:V-Legendre/dotfiles.git
cd dotfiles
./install.sh
```

Existing files are backed up as `.bak` before being replaced with symlinks. Safe to re-run.

## Adding a new project's .zed config

1. Copy the files into `projects/<name>/.zed/`
2. Re-run `./install.sh`
