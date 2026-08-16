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
  copyDesktopItems,
  makeDesktopItem,
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

    # Create a fake Xcode bundle to wrap xcodebuild without breaking xcrun validation
    export REAL_DEV_DIR=/Applications/Xcode.app/Contents/Developer
    export FAKE_XCODE="$(pwd)/FakeXcode.app"
    export FAKE_DEV_DIR="$FAKE_XCODE/Contents/Developer"
    
    mkdir -p "$FAKE_DEV_DIR/usr/bin"
    
    # Symlink the required plists for xcrun to consider this a valid Xcode
    ln -s /Applications/Xcode.app/Contents/Info.plist "$FAKE_XCODE/Contents/"
    ln -s /Applications/Xcode.app/Contents/version.plist "$FAKE_XCODE/Contents/"
    
    # Symlink all contents of the real developer dir and recreate Toolchains bin dir
    for file in "$REAL_DEV_DIR"/*; do
        if [[ "$(basename "$file")" == "Toolchains" ]]; then
            mkdir -p "$FAKE_DEV_DIR/Toolchains"
            for tc in "$REAL_DEV_DIR/Toolchains"/*; do
                if [[ "$(basename "$tc")" == "XcodeDefault.xctoolchain" ]]; then
                    mkdir -p "$FAKE_DEV_DIR/Toolchains/XcodeDefault.xctoolchain"
                    for d in "$REAL_DEV_DIR/Toolchains/XcodeDefault.xctoolchain"/*; do
                        if [[ "$(basename "$d")" == "usr" ]]; then
                            mkdir -p "$FAKE_DEV_DIR/Toolchains/XcodeDefault.xctoolchain/usr"
                            for ud in "$REAL_DEV_DIR/Toolchains/XcodeDefault.xctoolchain/usr"/*; do
                                if [[ "$(basename "$ud")" == "bin" ]]; then
                                    mkdir -p "$FAKE_DEV_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin"
                                    for b in "$REAL_DEV_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin"/*; do
                                        ln -s "$b" "$FAKE_DEV_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/"
                                    done
                                else
                                    ln -s "$ud" "$FAKE_DEV_DIR/Toolchains/XcodeDefault.xctoolchain/usr/"
                                fi
                            done
                        else
                            ln -s "$d" "$FAKE_DEV_DIR/Toolchains/XcodeDefault.xctoolchain/"
                        fi
                    done
                else
                    ln -s "$tc" "$FAKE_DEV_DIR/Toolchains/"
                fi
            done
        elif [[ "$(basename "$file")" != "usr" ]]; then
            ln -s "$file" "$FAKE_DEV_DIR/"
        fi
    done
    
    # Handle usr/
    mkdir -p "$FAKE_DEV_DIR/usr"
    for file in "$REAL_DEV_DIR/usr"/*; do
        if [ "$(basename "$file")" != "bin" ]; then
            ln -s "$file" "$FAKE_DEV_DIR/usr/"
        fi
    done
    mkdir -p "$FAKE_DEV_DIR/usr/bin"
    for file in "$REAL_DEV_DIR/usr/bin"/*; do
        ln -s "$file" "$FAKE_DEV_DIR/usr/bin/"
    done
    
    # Replace xcodebuild with our wrapper
    rm -f "$FAKE_DEV_DIR/usr/bin/xcodebuild"
    cat << 'EOF2' > "$FAKE_DEV_DIR/usr/bin/xcodebuild"
    #!/bin/bash
    exec "$REAL_DEV_DIR/usr/bin/xcodebuild" ARCHS=$(uname -m) ONLY_ACTIVE_ARCH=YES -IDEPackageSupportDisableManifestSandbox=YES -IDEPackageSupportDisablePluginExecutionSandbox=YES "$@"
    EOF2
    chmod +x "$FAKE_DEV_DIR/usr/bin/xcodebuild"

    LIPO_SCRIPT=$(cat << 'EOF3'
    #!/bin/bash
    echo "LIPO WRAPPER CALLED WITH: $@" >&2
    for i in "$@"; do
        if [[ "$next_is_out" == "1" ]]; then
            out_file="$i"
            break
        elif [[ "$i" == "-o" || "$i" == "-output" ]]; then
            next_is_out=1
        fi
    done
    echo "LIPO WRAPPER out_file: $out_file" >&2
    if [[ -n "$out_file" ]]; then
        dir_to_fix="$(dirname "$out_file")"
        echo "LIPO WRAPPER dir_to_fix: $dir_to_fix" >&2
        ls -ld "$dir_to_fix" >&2
        chmod -R +w "$dir_to_fix" 2>&1 | sed 's/^/CHMOD: /' >&2
        chmod -R +w "$dir_to_fix/.." 2>&1 | sed 's/^/CHMOD: /' >&2
        chmod -R +w "$dir_to_fix/../.." 2>&1 | sed 's/^/CHMOD: /' >&2
        ls -ld "$dir_to_fix" >&2
    fi
    exec "$REAL_DEV_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/lipo" "$@"
    EOF3
    )
    
    mkdir -p "$(pwd)/custom_bin"
    echo "$LIPO_SCRIPT" > "$(pwd)/custom_bin/lipo"
    chmod +x "$(pwd)/custom_bin/lipo"
    
    # OVERRIDE LIPO IN FAKE_DEV_DIR
    rm -f "$FAKE_DEV_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/lipo"
    cp "$(pwd)/custom_bin/lipo" "$FAKE_DEV_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/lipo"
    
    cat << 'EOF_XCRUN' > "$(pwd)/custom_bin/xcrun"
    #!/bin/bash
    if [[ "$1" == "lipo" ]]; then
        shift
        exec "$(pwd)/custom_bin/lipo" "$@"
    else
        exec /usr/bin/xcrun "$@"
    fi
    EOF_XCRUN
    chmod +x "$(pwd)/custom_bin/xcrun"
    
    export DEVELOPER_DIR="$FAKE_DEV_DIR"
    export PATH="$(pwd)/custom_bin:$PATH"
    
    # Nixpkgs sets LD=ld, which causes xcodebuild to invoke ld directly
    # but still pass -Xlinker flags meant for clang. Unset it to use default.
    unset LD
    
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
  ] ++ [
    copyDesktopItems
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
          
          mv ./rinf_patched/cargokit/run_build_tool.sh ./rinf_patched/cargokit/run_build_tool.orig.sh
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
    else
        exec "$(dirname "$0")/run_build_tool.orig.sh" "$@"
    fi
    EOF
          chmod +x ./rinf_patched/cargokit/run_build_tool.sh
          sed -i "s|$RINF_PATH|$(pwd)/rinf_patched|g" .dart_tool/package_config.json
        fi
  '';

  dontUseCmakeConfigure = true;

  desktopItems = [
    (makeDesktopItem {
      name = "uplink";
      exec = "uplink";
      icon = "uplink";
      desktopName = "Uplink";
      genericName = "Pastebin";
      comment = "Cross-platform pastebin GUI";
      categories = [
        "Network"
        "Utility"
      ];
      startupWMClass = "com.example.uplink";
    })
  ];

  postInstall = ''
    install -Dm644 assets/icon.png $out/share/icons/hicolor/512x512/apps/uplink.png
  '';

  meta = with lib; {
    description = "Uplink - Cross-platform pastebin GUI app";
    homepage = "https://github.com/example/uplink";
    license = licenses.mit;
    mainProgram = "uplink";
    maintainers = [ ];
    platforms = platforms.unix;
  };
}) (old: { __noChroot = true; })
