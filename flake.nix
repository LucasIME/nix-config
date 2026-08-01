{
  description = "nixos system config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    lanzaboote.url = "github:nix-community/lanzaboote/v1.1.0";
  };

  outputs = { self, nixpkgs, lanzaboote, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        lanzaboote.nixosModules.lanzaboote
      ];
    };
  };
}
