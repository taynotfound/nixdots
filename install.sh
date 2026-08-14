#!/usr/bin/env bash
# NixDots installer — never touches /etc/nixos automatically.
# Copies dotfiles and prints what to add to your configuration.nix.
set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CFG="$HOME/.config"
BIN="$HOME/.local/bin"

echo "==> Copying dotfiles..."
mkdir -p "$CFG/hypr" "$CFG/waybar" "$BIN"

cp -f "$REPO/hypr/hyprland.conf"  "$CFG/hypr/hyprland.conf"
cp -f "$REPO/hypr/hyprlock.conf"  "$CFG/hypr/hyprlock.conf"
cp -f "$REPO/hypr/hypridle.conf"  "$CFG/hypr/hypridle.conf"
cp -f "$REPO/waybar/config.jsonc" "$CFG/waybar/config.jsonc"
cp -f "$REPO/waybar/style.css"    "$CFG/waybar/style.css"

cp -f "$REPO/scripts/nixdots-windowctl" "$BIN/nixdots-windowctl"
chmod +x "$BIN/nixdots-windowctl"

cat > "$BIN/nixdots-screenshot" <<'SCRIPT'
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
chmod +x "$BIN/nixdots-screenshot"

echo ""
echo "==> Dotfiles copied."
echo ""
echo "=========================================================="
echo " Add this to your /etc/nixos/configuration.nix, then run:"
echo "   sudo nixos-rebuild switch"
echo "=========================================================="
cat <<'NIX'

  # ── NixDots ────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  programs.hyprland.enable = true;

  services.displayManager.sddm = {
    enable     = true;
    wayland.enable = true;
  };

  # NVIDIA (RTX/GTX 20xx+ proprietary)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    open           = false;
    nvidiaSettings = true;
    package        = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  services.pipewire = {
    enable          = true;
    alsa.enable     = true;
    alsa.support32Bit = true;
    pulse.enable    = true;
  };
  hardware.bluetooth.enable = true;

  fonts.packages = with pkgs; [
    inter
    nerd-fonts.jetbrains-mono
    font-awesome_6
    noto-fonts
    noto-fonts-color-emoji
  ];

  environment.systemPackages = with pkgs; [
    hyprlock hypridle hyprpicker
    waybar swaynotificationcenter wlogout
    nwg-dock-hyprland nwg-drawer rofi
    grim slurp wl-clipboard cliphist
    brightnessctl playerctl pavucontrol
    networkmanagerapplet blueman
    kitty firefox
    kdePackages.dolphin kdePackages.ark
    papirus-icon-theme bibata-cursors adw-gtk3 nwg-look
    git wget curl jq libnotify btop fastfetch
    unzip zip nano wev
  ];

  xdg.portal = {
    enable        = true;
    extraPortals  = [ pkgs.xdg-desktop-portal-hyprland ];
  };
  # ── end NixDots ────────────────────────────────────────────────

NIX
echo "=========================================================="
echo ""
echo "After reboot: log out, pick Hyprland in SDDM."
echo "Run ./update.sh any time to re-copy dotfiles."
