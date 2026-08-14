#!/usr/bin/env bash
# NixDots installer.
# Writes /etc/nixos/nixdots.nix and adds one imports line to configuration.nix.
# Your existing configuration.nix is otherwise untouched.
set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CFG="$HOME/.config"
BIN="$HOME/.local/bin"

# ── dotfiles ──────────────────────────────────────────────────────────────────
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

# ── write /etc/nixos/nixdots.nix ──────────────────────────────────────────────
echo "==> Writing /etc/nixos/nixdots.nix..."
sudo tee /etc/nixos/nixdots.nix > /dev/null <<'NIX'
{ config, pkgs, lib, ... }: {
  nixpkgs.config.allowUnfree = true;

  programs.hyprland.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # NVIDIA RTX/GTX — proprietary driver + Wayland requirements
  boot.kernelParams = [ "nvidia-drm.modeset=1" ];
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    open           = false;
    nvidiaSettings = true;
    package        = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.stable;
  };

  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
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
    enable       = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };
}
NIX

# ── inject imports line if not already present ────────────────────────────────
if ! grep -q "nixdots.nix" /etc/nixos/configuration.nix; then
  echo "==> Adding nixdots.nix to imports in /etc/nixos/configuration.nix..."
  sudo sed -i 's|imports = \[|imports = [\n    ./nixdots.nix|' /etc/nixos/configuration.nix
else
  echo "==> nixdots.nix already in imports, skipping."
fi

# ── rebuild ───────────────────────────────────────────────────────────────────
echo "==> Running nixos-rebuild switch..."
sudo nixos-rebuild switch

echo ""
echo "Done. Reboot and pick Hyprland in SDDM."
echo "Run ./update.sh any time to re-copy dotfiles without rebuilding."
