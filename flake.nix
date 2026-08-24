{
  description = "INCY Desktop VPN client for NixOS (Xray-based, Kotlin/JVM)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      incy = pkgs.callPackage ./incy.nix { inherit pkgs lib; };
    in
    {
      packages.${system} = {
        default = incy;
        incy = incy;
      };

      apps.${system} = {
        default = {
          type = "app";
          program = "${incy}/bin/incy";
        };
      };

      overlays.default = final: prev: {
        incy = self.packages.${system}.default;
      };

      nixosModules.default = { pkgs, ... }: {
        nixpkgs.overlays = [ self.overlays.default ];
        imports = [ ./incy-module.nix ];
      };
    };
}