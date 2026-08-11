{
  lib,
  stdenv,
  flutter,
  rustPlatform,
  cargo,
  rustc,
  pkg-config,
  cmake,
  ninja,
  clang,
  gtk3,
  glib,
  pcre2,
  cocoapods,
  cacert,
  wrapGAppsHook3,
  writableTmpDirAsHomeHook,
  callPackage,
}:

let
  buildFlutterApp = callPackage ./build-support/build-flutter-application.nix {};
in
lib.overrideDerivation (buildFlutterApp {
  pname = "uplink";
  version = "0.1.0";
  src = ./.;


  targetFlutterPlatform = "linux"; # Bypass nixpkgs assertion, we will override buildPhase

  buildPhase = if stdenv.hostPlatform.isDarwin then ''
    runHook preBuild
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
    export PATH="$DEVELOPER_DIR/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
    
    # CoreFoundation bypasses HOME, so we need to set CFFIXED_USER_HOME
    export CFFIXED_USER_HOME=$HOME

    # Disable Xcode User Script Sandboxing which breaks under Nix
    echo 'ENABLE_USER_SCRIPT_SANDBOXING = NO' >> macos/Flutter/Flutter-Release.xcconfig
    echo 'ENABLE_USER_SCRIPT_SANDBOXING = NO' >> macos/Flutter/Flutter-Debug.xcconfig

    LIPO_SCRIPT=$(cat << 'EOF3'
    #!/bin/bash
    echo "FAKE LIPO CALLED WITH ARGS: $@" >&2
    for i in "$@"; do
        if [[ "$next_is_out" == "1" ]]; then
            out_file="$i"
            break
        elif [[ "$i" == "-o" || "$i" == "-output" ]]; then
            next_is_out=1
        fi
    done
    if [[ -n "$out_file" ]]; then
        dir_to_fix="$(dirname "$out_file")"
        chmod -R +w "$dir_to_fix" || true
        chmod -R +w "$dir_to_fix/.." || true
        chmod -R +w "$dir_to_fix/../.." || true
    fi
    exec "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/lipo" "$@"
    EOF3
    )
    
    mkdir -p "$(pwd)/custom_bin"
    echo "$LIPO_SCRIPT" > "$(pwd)/custom_bin/lipo"
    chmod +x "$(pwd)/custom_bin/lipo"
    
    export PATH="$(pwd)/custom_bin:$PATH"
    
    echo "DEBUG: which lipo:"
    which lipo
    echo "DEBUG: lipo test:"
    lipo -info /bin/ls || true
    echo "DEBUG: xcrun --find lipo:"
    xcrun --find lipo || true

    flutter build macos -v --release
    runHook postBuild
  '' else null;

  installPhase = if stdenv.hostPlatform.isDarwin then ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -r build/macos/Build/Products/Release/uplink.app $out/Applications/
    runHook postInstall
  '' else null;

  sandboxProfile = if stdenv.hostPlatform.isDarwin then ''
    (allow file-read* file-write* process-exec mach-lookup)
    (deny file-read* file-write* process-exec mach-lookup (subpath "/usr/local") (with no-log))
  '' else "";

  autoPubspecLock = ./pubspec.lock;

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
  };

  nativeBuildInputs = [
    cargo
    rustc
    pkg-config
    cmake
    cocoapods
    cacert
    ninja
    rustPlatform.cargoSetupHook
    clang
    wrapGAppsHook3
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    writableTmpDirAsHomeHook
  ];

  buildInputs = [
    gtk3
    glib
    pcre2
  ];

  preBuild = ''
        mkdir -p .bin
        cp ./rustup-fake.sh .bin/rustup
        chmod +x .bin/rustup
        
        # Fake sw_vers for flutter on macOS
        echo '#!/bin/sh' > .bin/sw_vers
        echo 'echo "ProductName: macOS"' >> .bin/sw_vers
        echo 'echo "ProductVersion: 13.0"' >> .bin/sw_vers
        echo 'echo "BuildVersion: 22A380"' >> .bin/sw_vers
        chmod +x .bin/sw_vers
        
        export PATH="$(pwd)/.bin:$PATH"
        
        # Copy rinf from pub cache to local directory and patch it
        RINF_PATH=$(grep '"name": "rinf"' .dart_tool/package_config.json -A 2 | grep rootUri | cut -d'"' -f4 | sed 's|^file://||')
        if [ -n "$RINF_PATH" ]; then
          echo "Patching rinf at $RINF_PATH"
          cp -r "$RINF_PATH" ./rinf_patched
          chmod -R +w ./rinf_patched
          
          cat << 'EOF' > ./rinf_patched/cargokit/run_build_tool.sh
    #!/bin/sh
    set -ex
    if [ "$1" = "build-cmake" ]; then
        MANIFEST="$CARGOKIT_MANIFEST_DIR/Cargo.toml"
        export CARGO_TARGET_DIR="$CARGOKIT_MANIFEST_DIR/../../target"
        if [ "$CARGOKIT_CONFIGURATION" = "Release" ]; then
            cargo build --manifest-path "$MANIFEST" --release
            cp -v "$CARGO_TARGET_DIR/release/libhub.so" "$CARGOKIT_OUTPUT_DIR/libhub.so"
        else
            cargo build --manifest-path "$MANIFEST"
            cp -v "$CARGO_TARGET_DIR/debug/libhub.so" "$CARGOKIT_OUTPUT_DIR/libhub.so"
        fi
    fi
    EOF
          chmod +x ./rinf_patched/cargokit/run_build_tool.sh
          sed -i "s|$RINF_PATH|$(pwd)/rinf_patched|g" .dart_tool/package_config.json
        fi
  '';

  dontUseCmakeConfigure = true;

  meta = with lib; {
    description = "Uplink - Cross-platform pastebin GUI app";
    homepage = "https://github.com/example/uplink";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.unix;
  };
}) (old: { __noChroot = true; })
