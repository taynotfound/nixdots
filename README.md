# NixDots

A NixOS 26.05 + Hyprland 0.56 configuration that behaves like a normal
desktop environment while keeping Hyprland's advantages.

- Floating, centered windows by default (SUPER+T toggles tiling)
- Real titlebars (hyprbars) with Close / Maximize / Minimize / Hide buttons
- Titlebar dragging and border resizing like a normal DE
- Waybar top panel with minimized/hidden window shelves
- nwg-dock application dock, Rofi launcher, SwayNC notifications
- PipeWire audio, Bluetooth, NetworkManager, clipboard history (SUPER+V)
- hyprlock + hypridle lock/idle handling, screenshots (Print / SHIFT+Print)
- Working file pickers (GTK portal), GUI privilege prompts (hyprpolkitagent),
  removable drives (udisks2), keyring, Qt Wayland
- NVIDIA support with per-generation open/proprietary kernel module selection
- Steam + GameMode + Gamescope (disable with `gaming = false` in
  `hosts/local.nix`)

## Configuration format

Hyprland is configured in **Lua** (`hyprland.lua`), the recommended format
since Hyprland 0.56. Home Manager 26.05 generates it via
`wayland.windowManager.hyprland.configType = "lua"`. The config lives in
`home/hyprland.nix` as explicit Lua because Home Manager's automatic
settings→Lua conversion still has open bugs in 26.05.

## Install

On an already-installed NixOS system:

```bash
git clone https://github.com/taynotfound/nixdots.git
cd nixdots
./install.sh
```

The installer:

1. Detects user, hostname, timezone, existing `system.stateVersion`
   (preserved, never bumped), bootloader (systemd-boot / GRUB-EFI /
   GRUB-BIOS) and NVIDIA GPU generation.
2. Writes `hosts/local.nix` + copies your `hardware-configuration.nix`
   (both stay local, never committed).
3. Runs `nix flake check`, then **builds the complete system** before
   switching. If the build fails, nothing on your system changed.

Overrides: `NIXDOTS_USER`, `NIXDOTS_HOSTNAME`, `NIXDOTS_TIMEZONE`,
`NIXDOTS_STATE_VERSION`, `NIXDOTS_BOOTLOADER`, `NIXDOTS_BOOT_DEVICE`.
After installation, edit `hosts/local.nix` directly (e.g. `nvidiaOpen`,
`gaming`).

## Update

```bash
./update.sh                        # pull NixDots + update flake inputs
NIXDOTS_NO_INPUT_UPDATE=1 ./update.sh   # pull NixDots code only
```

Refuses to run on a dirty tree, pulls `--ff-only`, builds fully before
switching. `flake.lock` is committed; fresh clones use the exact tested
input revisions.

## Validate

```bash
./check.sh
```

Runs shellcheck, Waybar JSONC validation and `nix flake check`, which
evaluates and builds a CI fixture system (`hosts/ci.nix`) so the repository
is testable from a clean clone without your hardware files. On an installed
machine it additionally builds the real system.

## Remove

```bash
./remove.sh
```

Prints the accurate uninstall procedure (switch to a pre-NixDots generation
or rebuild from `/etc/nixos`) instead of blindly rolling back one
generation, and does not delete anything by itself.

## Keys

| Key | Action |
|-----|--------|
| SUPER+D / SUPER+R | Launcher |
| SUPER+Q | Terminal |
| SUPER+E | Files |
| SUPER+F | Maximize / restore |
| SUPER+M / SUPER+SHIFT+M | Minimize / restore minimized |
| SUPER+H / SUPER+SHIFT+H | Hide / restore hidden |
| SUPER+C / ALT+F4 | Close |
| SUPER+T | Toggle floating |
| SUPER+V | Clipboard history |
| SUPER+L | Lock |
| Print / SHIFT+Print | Region / full screenshot |
| XF86 media & brightness keys | Volume, mute, mic mute, play/pause, next/prev, brightness |

## Layout

```
flake.nix, flake.lock     pinned inputs (NixOS 26.05, HM 26.05, Hyprland 0.56.2)
hosts/                    ci fixture + local examples (real host files stay local)
nixos/configuration.nix   system: boot, NVIDIA, portals, polkit, audio, gaming
home/home.nix             user packages, theming, mime, dotfiles
home/hyprland.nix         Hyprland Lua config + hyprbars + binds
hypr/                     hyprlock / hypridle
waybar/, nwg-dock-hyprland/, scripts/
```
