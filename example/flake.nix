{
  inputs = {
    playdate-sdk.url = "github:RegularTetragon/playdate-sdk-flake";
  };
  outputs = {self, nixpkgs, playdate-sdk, ...}: 
  let system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      stdenv = pkgs.stdenv;
      playdate-sdk-pkg = playdate-sdk.packages.${system}.default;
  in
  {
    devShells.x86_64-linux.default = with stdenv; pkgs.mkShell {
      packages = [playdate-sdk-pkg];
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
      nativeBuildInputs = [playdate-sdk-pkg pkgs.gcc-arm-embedded pkgs.cmake];
      buildInputs = [ ];
      cmakeFlags = ["-DPLAYDATE_SDK_PATH=`pwd`/.PlaydateSDK"];
      configurePhase =  ''
      export PLAYDATE_SDK_PATH=${playdate-sdk-pkg}
      mkdir build
      cd build
      cmake ..
      make
      cd ..
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
