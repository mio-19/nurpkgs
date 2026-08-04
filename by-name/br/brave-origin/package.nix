{ lib, pkgs }:

# Build Brave from source using an FHS environment.
# FHS provides /usr/bin/env and lets depot_tools, gclient, vpython3 work correctly.

let
  # Python env with all modules depot_tools needs
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    httplib2
    requests
    six
    setuptools
    pip
  ]);

  fhsEnv = pkgs.buildFHSEnv {
    name = "brave-build-env";
    targetPkgs = pkgs: with pkgs; [
      # Core build tools
      git
      pythonEnv
      nodejs
      pnpm
      ninja
      pkg-config
      gn
      curl
      wget
      cacert
      bash
      which
      lsb-release
      # Compiler toolchain
      gcc
      binutils
      # C/C++ libraries for Chromium
      glib
      glib.dev
      nss
      nspr
      atk
      at-spi2-atk
      cups
      dbus
      pango
      cairo
      libxkbcommon
      libxkbcommon.dev
      # X11
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxcb
      # Other system libs
      alsa-lib
      mesa
      libdrm
      udev
      libusb1
      fontconfig
      freetype
      expat
      zlib
      openssl
      glibc
    ];
    runScript = "bash";
  };

  buildScript = pkgs.writeShellScriptBin "build-brave-origin-from-source" ''
    set -euo pipefail

    BUILD_DIR="''${BUILD_DIR:-$HOME/brave-build}"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    echo "==> Build directory: $BUILD_DIR"

    # Expose depot_tools Python modules explicitly so gclient can import them
    export PYTHONPATH="${pythonEnv}/${pythonEnv.sitePackages}''${PYTHONPATH:+:$PYTHONPATH}"
    # Tell depot_tools not to self-update and not to use vpython
    export DEPOT_TOOLS_UPDATE=0
    export VPYTHON_BYPASS="manually managed python not supported by chrome operations"
    # SSL certs
    export GIT_SSL_CAINFO="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    export CURL_CA_BUNDLE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

    # Step 1: depot_tools
    echo "==> 1. Setting up depot_tools..."
    if [ ! -d depot_tools ]; then
      git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
    fi
    export PATH="$BUILD_DIR/depot_tools:$PATH"

    # Step 2: brave-core in the right place
    echo "==> 2. Cloning brave-core..."
    mkdir -p src
    if [ ! -d src/brave ]; then
      git clone https://github.com/brave/brave-core.git src/brave
    fi

    cd src/brave

    # Step 3: pnpm install + gclient sync (what pnpm run init does)
    echo "==> 3. Running pnpm run init..."
    pnpm run init

    # Step 4: compile
    echo "==> 4. Building brave (this will take many hours)..."
    pnpm run build

    echo "==> Build complete! Binary: $BUILD_DIR/src/out/Release/brave"
  '';
in
pkgs.writeShellScriptBin "brave-origin-build" ''
  exec ${fhsEnv}/bin/brave-build-env ${buildScript}/bin/build-brave-origin-from-source "$@"
''
