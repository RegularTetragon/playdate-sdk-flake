 {
  inputs = {};
  outputs = {self, nixpkgs, ...}:
    let system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system}.playdate-sdk = ./nix/playdate-sdk/playdate-sdk.nix;
      devShells.${system}.default = import ./shell.nix {
        inherit pkgs;
      };  
  };
}
