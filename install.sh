#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
features=(--extra-experimental-features 'nix-command flakes')

if ! command -v nix >/dev/null; then
  echo "nix is required. Run this on an installed NixOS system." >&2
  exit 1
fi
if ! command -v git >/dev/null; then
  if [[ "${NIXDOTS_BOOTSTRAPPED:-}" != 1 ]]; then
    echo "git is missing; bootstrapping it through Nix..."
    exec env NIXDOTS_BOOTSTRAPPED=1 nix "${features[@]}" shell nixpkgs#git --command "$repo_root/install.sh" "$@"
  fi
  echo "git is still unavailable inside the Nix environment." >&2
  exit 1
fi

if [[ ! -e /etc/NIXOS ]]; then
  echo "This installer is for an installed NixOS system." >&2
  exit 1
fi
if [[ ! -f /etc/nixos/hardware-configuration.nix ]]; then
  echo "Missing /etc/nixos/hardware-configuration.nix. Finish a normal NixOS install first." >&2
  exit 1
fi
if ! command -v sudo >/dev/null; then
  echo "sudo is required." >&2
  exit 1
fi

username="${NIXDOTS_USER:-${SUDO_USER:-$USER}}"
[[ "$username" != root ]] || { echo "Run as a normal user, not root." >&2; exit 1; }
host_name="${NIXDOTS_HOSTNAME:-$(hostnamectl --static 2>/dev/null || hostname)}"
time_zone="${NIXDOTS_TIMEZONE:-$(timedatectl show -p Timezone --value 2>/dev/null || true)}"
time_zone="${time_zone:-Europe/Berlin}"

# Preserve the state version of the existing installation. Never invent one.
state_version="${NIXDOTS_STATE_VERSION:-}"
if [[ -z "$state_version" ]]; then
  state_version="$(grep -rhoP 'system\.stateVersion\s*=\s*"\K[0-9.]+' /etc/nixos/ 2>/dev/null | head -n1 || true)"
fi
if [[ -z "$state_version" ]] && command -v nixos-version >/dev/null; then
  state_version="$(nixos-version | grep -oP '^[0-9]+\.[0-9]+' || true)"
fi
[[ -n "$state_version" ]] || {
  echo "Could not detect system.stateVersion. Set NIXDOTS_STATE_VERSION=YY.MM and rerun." >&2
  exit 1
}

# Bootloader: keep whatever the machine already boots with.
if [[ -n "${NIXDOTS_BOOTLOADER:-}" ]]; then
  boot_loader="$NIXDOTS_BOOTLOADER"
  boot_device="${NIXDOTS_BOOT_DEVICE:-nodev}"
elif [[ -d /sys/firmware/efi ]]; then
  if [[ -d /boot/loader ]] || command -v bootctl >/dev/null && bootctl is-installed >/dev/null 2>&1; then
    boot_loader="systemd-boot"
  else
    boot_loader="grub-efi"
  fi
  boot_device="nodev"
else
  boot_loader="grub-bios"
  if [[ -n "${NIXDOTS_BOOT_DEVICE:-}" ]]; then
    boot_device="$NIXDOTS_BOOT_DEVICE"
  else
    root_source="$(findmnt -no SOURCE / 2>/dev/null || true)"
    parent_disk="$(lsblk -ndo PKNAME "$root_source" 2>/dev/null | head -n1 || true)"
    [[ -n "$parent_disk" ]] || {
      echo "Could not determine the BIOS boot disk from the root filesystem." >&2
      echo "Set NIXDOTS_BOOT_DEVICE=/dev/your-disk and rerun the installer." >&2
      exit 1
    }
    boot_device="/dev/$parent_disk"
  fi
fi

# NVIDIA: detect presence and pick a kernel module default by GPU generation.
# Turing (TU1xx) and newer -> open modules; older -> proprietary.
# Override with nvidiaOpen in hosts/local.nix if detection is wrong.
has_nvidia=false
nvidia_open=true
for dev in /sys/bus/pci/devices/*; do
  [[ -r "$dev/vendor" && "$(<"$dev/vendor")" == 0x10de ]] || continue
  has_nvidia=true
  device_id="$(<"$dev/device")"
  # Pre-Turing NVIDIA PCI device IDs are below 0x1e00 (TU102 = 0x1e02).
  if (( device_id < 0x1e00 )); then
    nvidia_open=false
  fi
done

printf 'Preparing NixDots for %s on %s (boot: %s, NVIDIA: %s open=%s, stateVersion: %s)\n' \
  "$username" "$host_name" "$boot_loader" "$has_nvidia" "$nvidia_open" "$state_version"

cp /etc/nixos/hardware-configuration.nix "$repo_root/hosts/hardware-configuration.nix"
cat > "$repo_root/hosts/local.nix" <<EOF
{
  username = "$username";
  hostName = "$host_name";
  timeZone = "$time_zone";
  hasNvidia = $has_nvidia;
  nvidiaOpen = $nvidia_open;
  gaming = true;
  bootLoader = "$boot_loader";
  bootDevice = "$boot_device";
  stateVersion = "$state_version";
}
EOF

# Flakes only expose Git-visible files. Keep machine-local files uncommitted,
# but add intent-to-add entries while Nix evaluates the flake.
cleanup_git_visibility() {
  git -C "$repo_root" reset -- hosts/hardware-configuration.nix hosts/local.nix >/dev/null 2>&1 || true
}
trap cleanup_git_visibility EXIT
git -C "$repo_root" add -N -f hosts/hardware-configuration.nix hosts/local.nix

(cd "$repo_root" && nix "${features[@]}" flake check --no-build)

# Build the complete system BEFORE switching. If this fails, nothing changed.
sudo nixos-rebuild build \
  --flake "path:$repo_root#nixdots" \
  --option experimental-features 'nix-command flakes'
sudo nixos-rebuild switch \
  --flake "path:$repo_root#nixdots" \
  --option experimental-features 'nix-command flakes'

cat <<'DONE'

NixDots is installed. Log out and choose Hyprland in SDDM, or reboot.
SUPER+D apps, SUPER+Q terminal, SUPER+F maximize/restore,
SUPER+M / SUPER+SHIFT+M minimize/restore, SUPER+H / SUPER+SHIFT+H hide/restore,
SUPER+V clipboard history, Print region screenshot, SHIFT+Print full screenshot.
Run ./update.sh for future updates.
DONE
