# Headscale member gateway — standalone flake
# Configure via .member-env.nix (gitignored), then deploy.
{
  description = "Headscale member gateway LXC — subnet router for your home lab into a shared tailnet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { nixpkgs, ... }: {
    nixosConfigurations.headscale-gw = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
      ];
    };
  };
}