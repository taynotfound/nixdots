{ config, pkgs, inputs, local, ... }:
let
  windowctl = pkgs.writeShellApplication {
    name = "nixdots-windowctl";
    runtimeInputs = with pkgs; [ jq libnotify rofi ];
    text = builtins.readFile ../scripts/nixdots-windowctl;
  };

  screenshot = pkgs.writeShellApplication {
    name = "nixdots-screenshot";
    runtimeInputs = with pkgs; [ grim slurp wl-clipboard coreutils libnotify ];
    text = ''
      set -euo pipefail
      mode="''${1:-region}"
      dir="$HOME/Pictures/Screenshots"
      mkdir -p "$dir"
      file="$dir/$(date +'%Y-%m-%d_%H-%M-%S').png"
      case "$mode" in
        region) grim -g "$(slurp)" - | tee "$file" | wl-copy -t image/png ;;
        full)   grim - | tee "$file" | wl-copy -t image/png ;;
        *) echo "usage: nixdots-screenshot [region|full]" >&2; exit 2 ;;
      esac
      notify-send "Screenshot saved" "$file"
    '';
  };

  wctl = "${windowctl}/bin/nixdots-windowctl";
  sshot = "${screenshot}/bin/nixdots-screenshot";
in
{
  home.packages = [ windowctl screenshot ];

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

    extraConfig = ''
      monitor = ,preferred,auto,1

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

      animations {
        enabled = true
      }

      input {
        kb_layout = de
        follow_mouse = 1
        sensitivity = 0
        touchpad {
          natural_scroll = true
          tap_to_click = true
        }
      }

      misc {
        disable_hyprland_logo = true
        force_default_wallpaper = 0
        background_color = rgb(100b18)
        focus_on_activate = true
      }

      dwindle {
        pseudotile = true
        preserve_split = true
      }

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
          on_double_click = ${wctl} maximize

          # close  maximize  minimize  hide
          hyprbars-button = rgb(e24a5a), 16, , ${wctl} close
          hyprbars-button = rgb(7656d6), 16, , ${wctl} maximize
          hyprbars-button = rgb(4f4a62), 16, , ${wctl} minimize
          hyprbars-button = rgb(353044), 16, , ${wctl} hide
        }
      }

      # Desktop mode: float and center all windows. SUPER+T toggles.
      windowrulev2 = float, class:.*
      windowrulev2 = center, class:.*
      windowrulev2 = plugin:hyprbars:nobar, fullscreen:1

      bind = SUPER, Q, exec, kitty
      bind = SUPER, E, exec, dolphin
      bind = SUPER, D, exec, rofi -show drun
      bind = SUPER, R, exec, rofi -show drun
      bind = ALT, F4, exec, ${wctl} close
      bind = SUPER, C, exec, ${wctl} close
      bind = SUPER, F, fullscreen, 1
      bind = SUPER, M, exec, ${wctl} minimize
      bind = SUPER SHIFT, M, exec, ${wctl} restore minimized
      bind = SUPER, H, exec, ${wctl} hide
      bind = SUPER SHIFT, H, exec, ${wctl} restore hidden
      bind = SUPER, T, togglefloating
      bind = SUPER, L, exec, hyprlock
      bind = SUPER SHIFT, E, exec, wlogout

      bind = SUPER, V, exec, cliphist list | rofi -dmenu -p Clipboard | cliphist decode | wl-copy

      bind = , Print,       exec, ${sshot} region
      bind = SHIFT, Print,  exec, ${sshot} full

      bindl = , XF86AudioRaiseVolume,  exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+
      bindl = , XF86AudioLowerVolume,  exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bindl = , XF86AudioMute,         exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bindl = , XF86AudioMicMute,      exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      bindl = , XF86AudioPlay,         exec, playerctl play-pause
      bindl = , XF86AudioNext,         exec, playerctl next
      bindl = , XF86AudioPrev,         exec, playerctl previous
      bindl = , XF86MonBrightnessUp,   exec, brightnessctl set 5%+
      bindl = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

      bind = SUPER, left,  movefocus, l
      bind = SUPER, right, movefocus, r
      bind = SUPER, up,    movefocus, u
      bind = SUPER, down,  movefocus, d

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
      bindm = ALT,   mouse:272, movewindow
      bindm = ALT,   mouse:273, resizewindow

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
