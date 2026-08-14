#!/usr/bin/env bash
# Re-copy dotfiles and optionally rebuild. No flakes, no HM.
set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CFG="$HOME/.config"

mkdir -p "$CFG/hypr" "$CFG/waybar" "$HOME/.local/bin"

cp -f "$REPO/hypr/hyprland.conf" "$CFG/hypr/hyprland.conf"
cp -f "$REPO/hypr/hyprlock.conf"  "$CFG/hypr/hyprlock.conf"
cp -f "$REPO/hypr/hypridle.conf"  "$CFG/hypr/hypridle.conf"
cp -f "$REPO/waybar/config.jsonc" "$CFG/waybar/config.jsonc"
cp -f "$REPO/waybar/style.css"    "$CFG/waybar/style.css"
cp -f "$REPO/scripts/nixdots-windowctl" "$HOME/.local/bin/nixdots-windowctl"
chmod +x "$HOME/.local/bin/nixdots-windowctl"

if [[ "${1:-}" == "--rebuild" ]]; then
  sudo nixos-rebuild switch
fi

echo "Dotfiles updated. Restart Waybar/Hyprland to apply."
