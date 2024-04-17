{
  description = "Gaming on Nix";

  inputs = {
    nixpkgs.url = "github:ffinkdevs/nixpkgs/nixos-unstable-small";

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    chaotic.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = {self, ...} @ inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        ./lib
        ./modules
        ./pkgs
        ./tests
      ];

      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;
      };
    };

  # auto-fetch deps when `nix run/shell`ing
  nixConfig = {
    allowInsecure = true;
    extra-substituters = ["https://nix-gaming.cachix.org"];
    extra-trusted-public-keys = ["nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="];
  };
}
