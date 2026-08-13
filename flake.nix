{
  description = "Tay's modern NixOS + Hyprland desktop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Latest stable Hyprland release at the time of this refresh.
    hyprland.url = "github:hyprwm/Hyprland/v0.56.2";

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins/v0.56.0";
      inputs.hyprland.follows = "hyprland";
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, hyprland, ... }:
    let
      system = "x86_64-linux";
      local = import ./hosts/local.nix;
    in {
      nixosConfigurations.nixdots = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs local; };

        modules = [
          ./hosts/hardware-configuration.nix
          hyprland.nixosModules.default
          ./nixos/configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "nixdots-backup";
            home-manager.extraSpecialArgs = { inherit inputs local; };
            home-manager.users.${local.username} = import ./home/home.nix;
          }
        ];
      };
    };
}
