# Edit username/timezone here before running install.sh, or let install.sh set them.
{ config, pkgs, lib, ... }:
let
  username = builtins.getEnv "NIXDOTS_USER";
  timeZone = builtins.getEnv "NIXDOTS_TIMEZONE";
  hasNvidia = builtins.getEnv "NIXDOTS_NVIDIA" == "true";
in {
  imports = [ ./hardware-configuration.nix ];

  # Bootloader — UEFI. For BIOS set grub.devices instead.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = builtins.getEnv "NIXDOTS_HOSTNAME";
  networking.networkmanager.enable = true;

  time.timeZone = if timeZone != "" then timeZone else "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  # NVIDIA — safe to leave in even without the hardware; it's a no-op then.
  nixpkgs.config.allowUnfree = true;

  # NVIDIA — only enabled if install.sh detected an NVIDIA GPU.
  services.xserver.videoDrivers = lib.mkIf hasNvidia [ "nvidia" ];
  hardware.nvidia = lib.mkIf hasNvidia {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  hardware.graphics.enable = true;

  # Hyprland + SDDM
  programs.hyprland.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Sound
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  hardware.bluetooth.enable = true;

  # User
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    shell = pkgs.bash;
  };

  # Fonts
  fonts.packages = with pkgs; [
    inter
    nerd-fonts.jetbrains-mono
    font-awesome_6
    noto-fonts
    noto-fonts-color-emoji
  ];

  # Packages installed system-wide
  environment.systemPackages = with pkgs; [
    # Desktop
    hyprlock hypridle hyprpicker
    waybar swaynotificationcenter wlogout
    nwg-dock-hyprland nwg-drawer rofi
    grim slurp wl-clipboard cliphist
    brightnessctl playerctl pavucontrol
    networkmanagerapplet blueman
    # Apps
    kitty firefox
    kdePackages.dolphin kdePackages.ark
    # Themes
    papirus-icon-theme bibata-cursors adw-gtk3 nwg-look
    # Utils
    git wget curl jq libnotify btop fastfetch
    unzip zip nano pciutils usbutils wev
  ];

  # XDG portal for Hyprland
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "26.05";
}
