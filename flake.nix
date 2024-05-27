 {
  inputs = {};
  outputs = {self, nixpkgs, ...}:
    let system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
        playdate-sdk = import ./playdate-sdk.nix {
          inherit pkgs;
        };
    in {
      packages.${system}.default = playdate-sdk;
      devShells.${system}.default = pkgs.mkShell {
        packages = [playdate-sdk];
        shellHook = ''
          export PLAYDATE_NIX_PATH="${playdate-sdk.outPath}"
          export PLAYDATE_SDK_PATH=".PlaydateSDK"
          export SDL_AUDIODRIVER=pulseaudio
        '';
      };
  };
}
