let
  pkgs = import <nixpkgs> { };
in
pkgs.stdenv.mkDerivation {
  name = "openhuman-source";
  outputHashMode = "recursive";
  outputHashAlgo = "sha256";
  outputHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

  nativeBuildInputs = [
    pkgs.git
    pkgs.cacert
  ];

  buildCommand = ''
    export HOME=$(pwd)
    git config --global url."https://github.com/".insteadOf git@github.com:
    git clone --depth 1 --branch v0.63.21 https://github.com/tinyhumansai/openhuman.git $out
    cd $out
    git submodule update --init --recursive
    find $out -name .git -type d -exec rm -rf {} +
    find $out -name .git -type f -exec rm -f {} +
  '';
}
