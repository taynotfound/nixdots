{ config, pkgs, inputs, local, ... }:
let
  windowctl = pkgs.writeShellApplication {
    name = "nixdots-windowctl";
    runtimeInputs = with pkgs; [ jq libnotify rofi-wayland ];
    text = builtins.readFile ../scripts/nixdots-windowctl;
  };

  screenshot = pkgs.writeShellApplication {
    name = "nixdots-screenshot";
    runtimeInputs = with pkgs; [ grim slurp wl-clipboard coreutils libnotify ];
    text = ''
      set -euo pipefail
      dir="$HOME/Pictures/Screenshots"
      mkdir -p "$dir"
      file="$dir/$(date +'%Y-%m-%d_%H-%M-%S').png"
      grim -g "$(slurp)" - | tee "$file" | wl-copy -t image/png
      notify-send "Screenshot saved" "$file"
    '';
  };
in
{
  home.username = local.username;
  home.homeDirectory = "/home/${local.username}";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    windowctl screenshot
    firefox kitty kdePackages.dolphin kdePackages.ark rofi-wayland
    waybar swaynotificationcenter wlogout nwg-dock-hyprland nwg-drawer
    hyprpaper hypridle hyprlock hyprpicker grim slurp wl-clipboard cliphist
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
  xdg.configFile."hypr/hyprlock.conf".source = ../hypr/hyprlock.conf;
  xdg.configFile."hypr/hypridle.conf".source = ../hypr/hypridle.conf;

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = true;
    plugins = [
      inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprbars
    ];

    # Standard Hyprland syntax: no generated/fake Lua layer.
    extraConfig = ''
      $terminal = kitty
      $fileManager = dolphin
      $menu = rofi -show drun
      $windowctl = ${windowctl}/bin/nixdots-windowctl
      $screenshot = ${screenshot}/bin/nixdots-screenshot

      monitor = , preferred, auto, 1
      env = XCURSOR_THEME,Bibata-Modern-Ice
      env = XCURSOR_SIZE,22
      env = HYPRCURSOR_SIZE,22

      general {
        gaps_in = 5
        gaps_out = 9
        border_size = 2
        resize_on_border = true
        extend_border_grab_area = 12
        layout = dwindle
        col.active_border = rgba(bf8cffdd) rgba(7f5af0dd) 45deg
        col.inactive_border = rgba(6e6780aa)
      }

      decoration {
        rounding = 12
        active_opacity = 1.0
        inactive_opacity = 0.96
        shadow {
          enabled = true
          range = 20
          render_power = 3
          color = rgba(08050dcc)
        }
        blur {
          enabled = true
          size = 7
          passes = 2
          vibrancy = 0.18
        }
      }

      animations { enabled = true }
      input {
        kb_layout = de
        follow_mouse = 1
        sensitivity = 0
        touchpad { natural_scroll = true; tap_to_click = true }
      }
      misc {
        disable_hyprland_logo = true
        force_default_wallpaper = 0
        background_color = rgb(100b18)
        focus_on_activate = true
      }
      dwindle { pseudotile = true; preserve_split = true }

      # Desktop mode: windows float and center by default. SUPER+T toggles tiling.
      windowrulev2 = float, class:^(.*)$
      windowrulev2 = center, class:^(.*)$
      windowrulev2 = plugin:hyprbars:nobar, fullscreen:1

      plugin {
        hyprbars {
          bar_height = 30
          bar_color = rgba(191421ee)
          col.text = rgb(eeeaf7)
          bar_text_size = 11
          bar_text_weight = 500
          bar_text_font = Inter
          bar_text_align = left
          bar_buttons_alignment = right
          bar_padding = 10
          bar_button_padding = 5
          bar_part_of_window = true
          bar_precedence_over_border = true
          on_double_click = $windowctl maximize
          # Font Awesome 6 Free glyphs: close, maximize, minimize, hide.
          hyprbars-button = rgb(e24a5a), 16, , $windowctl close, rgb(ffffff)
          hyprbars-button = rgb(7656d6), 16, , $windowctl maximize, rgb(ffffff)
          hyprbars-button = rgb(4f4a62), 16, , $windowctl minimize, rgb(ffffff)
          hyprbars-button = rgb(353044), 16, , $windowctl hide, rgb(c9c3d8)
        }
      }

      bind = SUPER, Q, exec, $terminal
      bind = SUPER, E, exec, $fileManager
      bind = SUPER, D, exec, $menu
      bind = SUPER, R, exec, $menu
      bind = ALT, F4, exec, $windowctl close
      bind = SUPER, C, exec, $windowctl close
      bind = SUPER, F, exec, $windowctl maximize
      bind = SUPER, M, exec, $windowctl minimize
      bind = SUPER SHIFT, M, exec, $windowctl restore minimized
      bind = SUPER, H, exec, $windowctl hide
      bind = SUPER SHIFT, H, exec, $windowctl restore hidden
      bind = SUPER, T, togglefloating,
      bind = SUPER, L, exec, hyprlock
      bind = SUPER SHIFT, E, exec, wlogout
      bind = Print, exec, $screenshot

      bind = SUPER, left, movefocus, l
      bind = SUPER, right, movefocus, r
      bind = SUPER, up, movefocus, u
      bind = SUPER, down, movefocus, d
      bind = SUPER, 1, workspace, 1
      bind = SUPER, 2, workspace, 2
      bind = SUPER, 3, workspace, 3
      bind = SUPER, 4, workspace, 4
      bind = SUPER, 5, workspace, 5
      bind = SUPER, 6, workspace, 6
      bind = SUPER, 7, workspace, 7
      bind = SUPER, 8, workspace, 8
      bind = SUPER, 9, workspace, 9
      bind = SUPER SHIFT, 1, movetoworkspacesilent, 1
      bind = SUPER SHIFT, 2, movetoworkspacesilent, 2
      bind = SUPER SHIFT, 3, movetoworkspacesilent, 3
      bind = SUPER SHIFT, 4, movetoworkspacesilent, 4
      bind = SUPER SHIFT, 5, movetoworkspacesilent, 5
      bind = SUPER SHIFT, 6, movetoworkspacesilent, 6
      bind = SUPER SHIFT, 7, movetoworkspacesilent, 7
      bind = SUPER SHIFT, 8, movetoworkspacesilent, 8
      bind = SUPER SHIFT, 9, movetoworkspacesilent, 9
      bindm = SUPER, mouse:272, movewindow
      bindm = SUPER, mouse:273, resizewindow
      bindm = ALT, mouse:272, movewindow
      bindm = ALT, mouse:273, resizewindow

      exec-once = waybar
      exec-once = hypridle
      exec-once = swaync
      exec-once = nm-applet --indicator
      exec-once = blueman-applet
      exec-once = nwg-dock-hyprland -d -p bottom -i 42 -mb 10 -c 'rofi -show drun'
      exec-once = wl-paste --type text --watch cliphist store
      exec-once = wl-paste --type image --watch cliphist store
    '';
  };
}
