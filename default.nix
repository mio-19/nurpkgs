# This file describes your repository contents.
# It should return a set of nix derivations
# and optionally the special attributes `lib`, `modules` and `overlays`.
# It should NOT import <nixpkgs>. Instead, you should take pkgs as an argument.
# Having pkgs default to <nixpkgs> is fine though, and it lets you use short
# commands such as:
#     nix-build -A mypackage

{
  pkgs ? import <nixpkgs> {
    config.permittedInsecurePackages = [
      "qtwebengine-5.15.19"
    ];
  },
}:

rec {
  # The `lib`, `modules`, and `overlays` names are special
  lib = import ./lib { inherit pkgs; }; # functions
  modules = import ./modules; # NixOS modules
  overlays = import ./overlays; # nixpkgs overlays

  telegram-desktop = pkgs.telegram-desktop.overrideAttrs (old: {
    unwrapped = old.unwrapped.overrideAttrs (old2: {
      # see https://github.com/Layerex/telegram-desktop-patches
      patches = (pkgs.telegram-desktop.unwrapped.patches or [ ]) ++ [
        ./patches/0001-telegramPatches.patch
      ];
    });
  });
  materialgram = pkgs.materialgram.overrideAttrs (old: {
    unwrapped = old.unwrapped.overrideAttrs (old2: {
      # see https://github.com/Layerex/telegram-desktop-patches
      patches = (pkgs.materialgram.unwrapped.patches or [ ]) ++ [
        ./patches/0001-materialgramPatches.patch
      ];
    });
  });
  example-package = pkgs.callPackage ./pkgs/example-package { };
  lmms = pkgs.lib.mkIf pkgs.stdenv.isLinux (
    pkgs.callPackage ./pkgs/lmms/package.nix { withOptionals = true; }
  );
  minetest591 = pkgs.callPackage ./pkgs/minetest591 {
  };
  minetest591client = minetest591.override { buildServer = false; };
  minetest591server = minetest591.override { buildClient = false; };
  irrlichtmt = pkgs.callPackage ./pkgs/irrlichtmt {
  };
  minetest580 = pkgs.callPackage ./pkgs/minetest580 {
    irrlichtmt = irrlichtmt;
  };
  minetest580client = minetest580.override { buildServer = false; };
  minetest580-touch = minetest580.override {
    buildServer = false;
    withTouchSupport = true;
  };
  minetest580server = minetest580.override { buildClient = false; };
  musescore3 =
    if pkgs.stdenv.isDarwin then
      pkgs.callPackage ./pkgs/musescore3/darwin.nix { }
    else
      pkgs.libsForQt5.callPackage ./pkgs/musescore3 { };
  zen-browser = pkgs.callPackage ./pkgs/zen-browser/package.nix { };
  # some-qt5-package = pkgs.libsForQt5.callPackage ./pkgs/some-qt5-package { };
  # ...
}
