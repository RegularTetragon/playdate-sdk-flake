# playdate-sdk-flake
A nix flake for creating playdate sdk shells.

In short, this is a package description for Playdate Simulator, pdc, and pdutil written in nix to make installation easier. This script downloads the SDK from the website and does not provide the files itself.

# Provided binaries:
This flake provides pdc, pdutil, a wrapper script, an unwrapped version of PlaydateSimulator, and a wrapped version of PlaydateSimulator.

## pdc

The playdate compiler

## pdutil

A utility for talking to the playdate over USB

## pdwrapped

A wrapper for PlaydateSimulator that allows modification of a .PlaydateSDK directory.

## PlaydateSimulator

The original binary for the Playdate Simulator. Without the wrapper its a little bit janky to use on a nixos system. If your nix store is writable for some reason it shouldn't have any issues though.

## pdwrapper

A simple bash script for creating the .PlaydateSDK directory if it dosen't exist, and then running PlaydateSimulator from said directory. This lets it write to the Disk folder in .PlaydateSDK only, circumventing the read-only nature of the nix store.

# Basic Usage:

## As a shell
you can run the playdate simulator, pdc, or pdutil from a `nix shell` like so

```bash
nix shell github:RegularTetragon/playdate-sdk-flake#default

pdwrapper
pdc
pdutil
PlaydateSimulator
```

## In a project

A simple project's flake.nix could look like this:
```nix

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
    devShells.${system}.default = with stdenv; pkgs.mkShell {
      packages = [playdate-sdk-pkg];
      shellHook = ''
      export PLAYDATE_SDK_PATH=`pwd`/.PlaydateSDK
      '';
    };
  }
}
```
Now when you enter the directory you can run
```bash
nix develop
PlaydateSimulator
```

There is a more advanced example of a project flake in ./examples/ which allows you to build a pdx file like so
```bash
nix build
```

Once you've done that you can run
```bash
nix develop
PlaydateSimulator ./result/hello_world.pdx
```
