{
  pkgs,
  ...
}:
let
  oldPkgs = import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-23.11.tar.gz") { inherit (pkgs) system; };
in
oldPkgs.python38
