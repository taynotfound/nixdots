{ config, lib, pkgs, inputs, local, ... }:
let
  hyprPkgs = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # trusted-users would make wheel users root-equivalent for the Nix daemon.
    # Substituters/keys are configured system-wide here instead, so no user
    # ever needs to be a trusted user for the caches to work.
    substituters = [
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
    ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  networking.hostName = local.hostName;
  networking.networkmanager.enable = true;
  time.timeZone = local.timeZone;

  # Bootloader: install.sh detects the machine's existing setup and writes
  # local.bootLoader ("systemd-boot" | "grub-efi" | "grub-bios") + bootDevice.
  boot.loader = lib.mkMerge [
    (lib.mkIf ((local.bootLoader or "grub-bios") == "systemd-boot") {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    })
    (lib.mkIf ((local.bootLoader or "grub-bios") == "grub-efi") {
      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
      };
      efi.canTouchEfiVariables = true;
    })
    (lib.mkIf ((local.bootLoader or "grub-bios") == "grub-bios") {
      grub = {
        enable = true;
        device = local.bootDevice or "nodev";
      };
    })
  ];

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };
  console.keyMap = "de";
  services.xserver.xkb.layout = "de";

  users.users.${local.username} = {
    isNormalUser = true;
    description = local.username;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
    shell = pkgs.fish;
  };
  programs.fish.enable = true;

  # Hyprland's own module supplies the session entry, portal and Wayland plumbing.
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = hyprPkgs.hyprland;
    portalPackage = hyprPkgs.xdg-desktop-portal-hyprland;
  };

  # XDPH does not implement FileChooser; the GTK portal provides it.
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # GUI privilege prompts (pkexec etc.) need a running polkit agent.
  security.polkit.enable = true;
  systemd.user.services.hyprpolkitagent = {
    description = "Hyprland polkit authentication agent";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
    };
  };

  # A normal graphical login rather than dropping into a TTY.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.displayManager.defaultSession = "hyprland";

  security.rtkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  # Removable drives in Dolphin etc.
  services.udisks2.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # NVIDIA. install.sh detects the GPU generation and writes
  # local.nvidiaOpen; override it in hosts/local.nix when detection is wrong
  # (hybrid graphics, unusual cards). Upstream guidance:
  #   Turing (RTX 20xx) and newer -> open kernel modules recommended,
  #   50-series and newer -> open modules required,
  #   pre-Turing -> proprietary modules.
  services.xserver.videoDrivers = lib.optionals local.hasNvidia [ "nvidia" ];
  hardware.nvidia = lib.mkIf local.hasNvidia {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = local.nvidiaOpen or true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Gaming (optional, on by default for a desktop machine).
  programs.steam = lib.mkIf (local.gaming or true) {
    enable = true;
    gamescopeSession.enable = true;
  };
  programs.gamemode.enable = local.gaming or true;

  services.fstrim.enable = true;
  zramSwap.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
  };

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      inter
      noto-fonts
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
    ];
  };

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    unzip
    zip
    vim
    nano
    pciutils
    usbutils
    kdePackages.qtwayland
  ];

  # Preserved from the machine's original installation by install.sh.
  # Do NOT treat this as a version selector.
  system.stateVersion = local.stateVersion or "26.05";
}
