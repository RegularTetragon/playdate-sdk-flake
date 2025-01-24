{
  pkgs,
}: let
  stdenv = pkgs.stdenv;
  lib = pkgs.lib;
  # Build inputs for `pdc`
  pdcInputs = with pkgs; [
    stdenv.cc.cc.lib
    libpng
    zlib
  ];

  # Build inputs for the simulator (excluding those from pdc)
  pdsInputs = with pkgs; [
    udev
    gtk3
    pango
    cairo
    gdk-pixbuf
    glib
    webkitgtk
    xorg.libX11
    stdenv.cc.cc.lib
    libxkbcommon
    wayland
    libpulseaudio
    gsettings-desktop-schemas
  ];

  dynamicLinker = "${pkgs.glibc}/lib/ld-linux-x86-64.so.2";

  pdwrapper = {program}: ''
  '';
in
  stdenv.mkDerivation rec {
    pname = "playdate-sdk";
    version = "2.6.2";
    src = pkgs.fetchurl {
      url = "https://download.panic.com/playdate_sdk/Linux/PlaydateSDK-${version}.tar.gz";
      sha256 = "sha256-GDqXXPgBYSiKuxcV3M/Ho5ALX5IAOkx6neK6bZKYt7E=";
    };

    buildInputs = pdcInputs;
    nativeBuildInputs = [ pkgs.makeWrapper pkgs.wrapGAppsHook ];
    dontFixup = true;

    installPhase = ''
      runHook preInstall

      # Get our new root
      root=$out/opt/playdate-sdk-${version}

      # Everything else
      mkdir -p $out/opt/playdate-sdk-${version}
      cp -r ./ $out/opt/playdate-sdk-${version}
      ln -s $root $out/opt/playdate-sdk

      # Setup dependencies and interpreter
      patchelf \
        --set-interpreter "${dynamicLinker}" \
        --set-rpath "${lib.makeLibraryPath pdcInputs}" \
        $root/bin/pdc
      patchelf \
        --set-interpreter "${dynamicLinker}" \
        $root/bin/pdutil
      patchelf \
        --set-interpreter "${dynamicLinker}" \
        --set-rpath "${lib.makeLibraryPath pdsInputs}"\
        $root/bin/PlaydateSimulator

      # Binaries
      mkdir -p $out/bin

      cp $root/bin/pdc $out/bin/pdc
      cp $root/bin/pdutil $out/bin/pdutil
      cp $root/bin/PlaydateSimulator $out/bin/PlaydateSimulator

      # NixOS really hates writable install paths. Lets fake one

      cat > $out/bin/pdwrapper <<EOL
      #!/usr/bin/env bash
      if [ ! -d ".PlaydateSDK" ]; then
        read -p "pdwrapper> .PlaydateSDK not found. Create it in (\`pwd\`)? [y/n]" -n 1 -r
        echo
        if [[ ! \$REPLY =~ ^[Yy]$ ]] then
          echo "pdwrapper> cancelled."
          exit
        fi
        echo "pdwrapper> Creating .PlaydateSDK"
        mkdir .PlaydateSDK
        cp -TR $out/Disk .PlaydateSDK/Disk
        chmod -R 755 .PlaydateSDK/Disk
        cp -TR $out/bin .PlaydateSDK/bin
        ln -s $out/C_API .PlaydateSDK/C_API
        ln -s $out/CoreLibs .PlaydateSDK/CoreLibs
        ln -s $out/Resources .PlaydateSDK/Resources
      fi
      echo "pdwrapper> Running .PlaydateSDK/bin/PlaydateSimulator";
      export XDG_DATA_DIRS=$gsettings_schemas_path/share/gsettings-schemas/$gsettings_schemas_name:$gtk_path/share/gsettings-schemas/$gtk_name:$XDG_DATA_DIRS

      PLAYDATE_SDK_PATH=.PlaydateSDK exec -a \`pwd\`.PlaydateSDK/bin/PlaydateSimulator .PlaydateSDK/bin/PlaydateSimulator $@
      EOL
      chmod 555 $out/bin/pdwrapper

      cp -r $root/C_API $out/C_API
      cp -r $root/CoreLibs $out/CoreLibs
      cp -r $root/Resources $out/Resources
      cp -r $root/Disk $out/Disk

      runHook postInstall
    '';
    meta = with lib; {
      description = "the Panic Playdate game console SDK, contains the simulator PlaydateSimulator, the compiler pdc, and the util program pdutil.";
      homepage = "https://play.date/dev/";
      licenses = lib.licenses.unfree;

    };
  }
