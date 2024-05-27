# playdate-sdk-flake
A nix flake for creating playdate sdk shells.

In short, this is a package description for Playdate Simulator, pdc, and pdutil written in nix to make installation easier. This script downloads the SDK from the website and does not provide the files itself.

# Provided binaries:
This flake provides pdc, pdutil, a wrapper script, PlaydateSimulator, and a wrapped version of PlaydateSimulator.

## pdc

The playdate compiler. Run
```
pdc -h
```
or check the official documentation for more info

## pdutil

A utility for talking to the playdate over USB. Run
```
pdutil -h
```
or check the official documentation for more info

## PlaydateSimulator

The original binary for the Playdate Simulator. Without the wrapper its a little bit janky to use on a nixos system, though it should function for running your own pdx files:
```
PlaydateSimulator <filename.pdx>
```
check the official documenation for more info.

## pdwrapper
An unoffical wrapper for PlaydateSimulator. It dreates a .PlaydateSDK subdirectory in the current directory based on the current Playdate SDK in the environment. It's experimental and I don't recommend you use it, though at some point it may allow PlaydateSimulator to have its own writable sandbox.

# Basic Usage:

## As a shell
you can run the playdate simulator, pdc, or pdutil from a `nix shell` like so

```bash
nix shell github:RegularTetragon/playdate-sdk-flake#default

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
    };
  }
}
```
Now when you enter the directory you can run
```bash
nix develop
PlaydateSimulator
```

There is a more advanced example of a project flake in ./examples/ which supports `nix build` for testing, `nix build .#playdate-example-arm` for making the final build, and `nix run` to allow you to build and run a C based playdate project.
You should be able to just
```bash
cd exanple
nix run
```
