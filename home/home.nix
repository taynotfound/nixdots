{ config, pkgs, inputs, local, ... }:
{
  imports = [ ./hyprland.nix ];

  home.username = local.username;
  home.homeDirectory = "/home/${local.username}";
  # Initial Home Manager version for this configuration. Do not bump blindly.
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    firefox kitty kdePackages.dolphin kdePackages.ark rofi
    waybar swaynotificationcenter wlogout nwg-dock-hyprland nwg-drawer
    hypridle hyprlock hyprpicker grim slurp wl-clipboard cliphist
    brightnessctl playerctl pavucontrol networkmanagerapplet blueman wev
    papirus-icon-theme bibata-cursors adw-gtk3 nwg-look btop fastfetch jq
    font-awesome
  ];

  xdg.enable = true;
  xdg.userDirs = { enable = true; createDirectories = true; };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 22;
  };

  gtk = {
    enable = true;
    theme = { name = "adw-gtk3-dark"; package = pkgs.adw-gtk3; };
    iconTheme = { name = "Papirus-Dark"; package = pkgs.papirus-icon-theme; };
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 22;
    };
    font = { name = "Inter"; size = 10; };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };

  programs.kitty = {
    enable = true;
    settings = {
      font_family = "JetBrainsMono Nerd Font";
      font_size = 11;
      background_opacity = "0.94";
      window_padding_width = 10;
      confirm_os_window_close = 0;
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "inode/directory" = [ "org.kde.dolphin.desktop" ];
    };
  };

  xdg.configFile."waybar/config.jsonc".source = ../waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ../waybar/style.css;
  xdg.configFile."nwg-dock-hyprland/style.css".source = ../nwg-dock-hyprland/style.css;
}
