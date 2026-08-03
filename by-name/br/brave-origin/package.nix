{ lib, pkgs }:

# The BEST way forward to build Brave from source on Nix is to bypass the strict
# Nix sandbox using an FHS (Filesystem Hierarchy Standard) environment. 
# This provides a virtual Debian/Ubuntu-like environment where /usr/bin/env exists,
# and all the dynamic network fetching from depot_tools, python, and npm will succeed.

let
  brave-build-env = pkgs.buildFHSEnv {
    name = "brave-build-env";
    targetPkgs = pkgs: with pkgs; [
      git
      python3
      nodejs
      pnpm
      ninja
      pkg-config
      gn
      curl
      cacert
      bash
      which
      # Add necessary C/C++ dependencies for chromium
      glib
      nss
      nspr
      atk
      at-spi2-atk
      cups
      dbus
      pango
      cairo
      xorg.libX11
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXrandr
      xorg.libxcb
      alsa-lib
      mesa
      libdrm
    ];
    runScript = "bash";
  };
in
pkgs.writeShellScriptBin "build-brave-origin-from-source" ''
  echo "Entering FHS environment to build Brave from source..."
  exec ${brave-build-env}/bin/brave-build-env -c "
    set -e
    export GIT_SSL_NO_VERIFY=1
    
    echo '1. Setting up depot_tools...'
    if [ ! -d depot_tools ]; then
      git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
    fi
    export PATH=\$PWD/depot_tools:\$PATH
    
    echo '2. Cloning brave-core...'
    if [ ! -d brave-core ]; then
      git clone https://github.com/brave/brave-core.git
    fi
    cd brave-core
    
    echo '3. Running pnpm run init (fetches chromium)...'
    pnpm run init
    
    echo '4. Building the browser...'
    pnpm run build
    
    echo 'Build complete! Binary should be in out/Release/brave'
  "
''
