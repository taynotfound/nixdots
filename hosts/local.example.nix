{
  # install.sh rewrites this file for the machine it is run on.
  username = "tay";
  hostName = "nixdots";
  timeZone = "Europe/Berlin";

  # NVIDIA: hasNvidia enables the driver; nvidiaOpen selects the open kernel
  # modules (required on 50-series+, recommended on Turing/Ampere; set false
  # for pre-Turing cards that need the proprietary modules).
  hasNvidia = true;
  nvidiaOpen = true;

  # Steam / GameMode / Gamescope.
  gaming = true;

  # "systemd-boot" (UEFI), "grub-efi" (UEFI with GRUB) or "grub-bios".
  # install.sh detects this from the running system.
  bootLoader = "systemd-boot";
  # Only used for grub-bios: the disk GRUB installs to.
  bootDevice = "nodev";

  # Preserved from the machine's original NixOS installation.
  stateVersion = "26.05";
}
