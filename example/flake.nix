{
  inputs = {
    playdate-sdk.url = "github:RegularTetragon/playdate-sdk-flake";
  };
  outputs = {self, nixpkgs, playdate-sdk, ...}: 
  let system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      stdenv = pkgs.stdenv;
  in
  {
    devShells.x86_64-linux.default = with stdenv; pkgs.mkShell {
      packages = [pkgs.cmake];
      shellHook = ''
      export PLAYDATE_SDK_PATH=`pwd`/.PlaydateSDK
      '';
    };
    packages.x86_64-linux.default = with stdenv; mkDerivation rec {
      pname = "playdate-example";
      version = "1.0.0";
      src = with pkgs.lib.fileset; toSource {
        root = ./.;
        fileset = unions [
          ./CMakeLists.txt
          ./src
          ./Source
        ];
      };
      nativeBuildInputs = [pkgs.cmake];
      buildInputs = [playdate-sdk.packages.${system}.default pkgs.gcc-arm-embedded ];
      cmakeFlags = ["-DPLAYDATE_SDK_PATH=`pwd`/.PlaydateSDK"];
      configurePhase =  ''
      export PLAYDATE_SDK_PATH=${playdate-sdk.packages.${system}.default}
      echo "current sdk path $PLAYDATE_SDK_PATH"
      mkdir build
      cd build
      cmake ..
      make
      '';
      installPhase = ''
        export PLAYDATE_SDK_PATH=`pwd`/.PlaydateSDK
        runHook preInstall
        cp -r . $out
        runHook postInstall
      '';
    };
  };
}
