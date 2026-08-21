# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ---------------------------------------------------------------------------
# This file is shared by every machine. Anything machine-specific goes into a
# drop-in under ~/.zshrc.d/ (symlinked from shared/zshrc.d/ and
# hosts/<host>/zshrc.d/ by install.sh) — do not add host-specific paths here.
# ---------------------------------------------------------------------------

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=( git z zsh-nvm zsh-syntax-highlighting )
source $ZSH/oh-my-zsh.sh

# Prompt. To customize, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Drop-ins: 10-* are shared, 50-* are host-specific, 90-* are machine-local
# (untracked). Loaded in lexical order.
for _rc in "$HOME"/.zshrc.d/*.zsh(N); do
  source "$_rc"
done
unset _rc
