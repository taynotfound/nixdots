#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# ── preflight ────────────────────────────────────────────────────────────────
[[ -e /etc/NIXOS ]]                         || { echo "Run this on NixOS." >&2; exit 1; }
[[ -f /etc/nixos/hardware-configuration.nix ]] || { echo "Missing /etc/nixos/hardware-configuration.nix" >&2; exit 1; }
[[ $EUID -ne 0 ]]                           || { echo "Run as a normal user, not root." >&2; exit 1; }
command -v nixos-rebuild >/dev/null         || { echo "nixos-rebuild not found." >&2; exit 1; }

USER_NAME="${NIXDOTS_USER:-${SUDO_USER:-$USER}}"
HOST_NAME="${NIXDOTS_HOSTNAME:-$(hostname)}"
TIMEZONE="${NIXDOTS_TIMEZONE:-$(timedatectl show -p Timezone --value 2>/dev/null || echo Europe/Berlin)}"

echo "Installing NixDots for user=$USER_NAME host=$HOST_NAME tz=$TIMEZONE"

# ── system config ────────────────────────────────────────────────────────────
sudo cp /etc/nixos/hardware-configuration.nix "$REPO/hardware-configuration.nix"
sudo cp "$REPO/configuration.nix"             /etc/nixos/configuration.nix
sudo cp "$REPO/hardware-configuration.nix"    /etc/nixos/hardware-configuration.nix

# Stamp user/host/timezone into the live config
sudo sed -i \
  -e "s|builtins.getEnv \"NIXDOTS_USER\"|\"$USER_NAME\"|g" \
  -e "s|builtins.getEnv \"NIXDOTS_HOSTNAME\"|\"$HOST_NAME\"|g" \
  -e "s|builtins.getEnv \"NIXDOTS_TIMEZONE\"|\"$TIMEZONE\"|g" \
  /etc/nixos/configuration.nix

echo "Running nixos-rebuild switch..."
sudo nixos-rebuild switch

# ── dotfiles ──────────────────────────────────────────────────────────────────
CFG="$HOME/.config"
mkdir -p "$CFG/hypr" "$CFG/waybar" "$HOME/.local/bin"

cp -f "$REPO/hypr/hyprland.conf" "$CFG/hypr/hyprland.conf"
cp -f "$REPO/hypr/hyprlock.conf"  "$CFG/hypr/hyprlock.conf"
cp -f "$REPO/hypr/hypridle.conf"  "$CFG/hypr/hypridle.conf"
cp -f "$REPO/waybar/config.jsonc" "$CFG/waybar/config.jsonc"
cp -f "$REPO/waybar/style.css"    "$CFG/waybar/style.css"
cp -f "$REPO/scripts/nixdots-windowctl"  "$HOME/.local/bin/nixdots-windowctl"
chmod +x "$HOME/.local/bin/nixdots-windowctl"

cat > "$HOME/.local/bin/nixdots-screenshot" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
mode="${1:-region}"
dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +'%Y-%m-%d_%H-%M-%S').png"
case "$mode" in
  region) grim -g "$(slurp)" - | tee "$file" | wl-copy -t image/png ;;
  full)   grim - | tee "$file" | wl-copy -t image/png ;;
  *) echo "usage: nixdots-screenshot [region|full]" >&2; exit 2 ;;
esac
notify-send "Screenshot saved" "$file"
SCRIPT
chmod +x "$HOME/.local/bin/nixdots-screenshot"

echo ""
echo "Done. Log out and select Hyprland in SDDM, or reboot."
echo "Run ./update.sh to apply config changes without rebuilding."
