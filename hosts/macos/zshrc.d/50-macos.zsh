# macOS-specific shell configuration.

# Homebrew
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
fi

# Tailscale ships as an app bundle, not a CLI on PATH.
[[ -x "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]] && \
  alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

# Docker Desktop CLI completions
if [[ -d "$HOME/.docker/completions" ]]; then
  fpath=("$HOME/.docker/completions" $fpath)
  autoload -Uz compinit
  compinit
fi
