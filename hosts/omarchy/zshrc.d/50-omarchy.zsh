# Omarchy-specific shell configuration.
#
# Kept deliberately small: everything portable lives in the shared 10-*/20-*
# drop-ins. Add Arch/Hyprland-specific tweaks here.

[[ -d "$HOME/.local/share/omarchy/bin" ]] && \
  export PATH="$HOME/.local/share/omarchy/bin:$PATH"
