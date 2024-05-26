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
    version = "2.5.0";
    src = pkgs.fetchurl {
      url = "https://download.panic.com/playdate_sdk/Linux/PlaydateSDK-${version}.tar.gz";
      sha256 = "sha256-1b7j7lkN16YO4EUWyZPZ+PPC9Sa3AFoN5c84ArTGXok=";
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
      makeWrapper $root/bin/PlaydateSimulator $out/bin/PlaydateSimulator \
        --suffix XDG_DATA_DIRS : ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}\
        --set PLAYDATE_SDK_PATH .PlaydateSDK

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
        ln -s $out/bin .PlaydateSDK/bin
        ln -s $out/C_API .PlaydateSDK/C_API
        ln -s $out/CoreLibs .PlaydateSDK/CoreLibs
        ln -s $out/Resources .PlaydateSDK/Resources
      fi
      echo "pdwrapper> Running .PlaydateSDK/bin/\`basename \$0\`-unwrapped";
      PLAYDATE_SDK_PATH=.PlaydateSDK .PlaydateSDK/bin/PlaydateSimulator \$@
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
