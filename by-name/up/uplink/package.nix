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

    # Create a fake DEVELOPER_DIR to wrap xcodebuild since flutter hardcodes /usr/bin/arch xcrun
    export REAL_DEV_DIR=/Applications/Xcode.app/Contents/Developer
    export FAKE_DEV_DIR="$(pwd)/.developer_dir"
    mkdir -p "$FAKE_DEV_DIR/usr/bin"
    
    # Symlink all contents of the real developer dir
    for file in "$REAL_DEV_DIR"/*; do
        if [[ "$(basename "$file")" != "usr" && "$(basename "$file")" != "Toolchains" ]]; then
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

    # Handle Toolchains/ to wrap lipo
    mkdir -p "$FAKE_DEV_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin"
    for file in "$REAL_DEV_DIR/Toolchains"/*; do
        if [ "$(basename "$file")" != "XcodeDefault.xctoolchain" ]; then
            ln -s "$file" "$FAKE_DEV_DIR/Toolchains/"
        fi
    done
    for file in "$REAL_DEV_DIR/Toolchains/XcodeDefault.xctoolchain"/*; do
        if [ "$(basename "$file")" != "usr" ]; then
            ln -s "$file" "$FAKE_DEV_DIR/Toolchains/XcodeDefault.xctoolchain/"
        fi
    done
    mkdir -p "$FAKE_DEV_DIR/Toolchains/XcodeDefault.xctoolchain/usr"
    for file in "$REAL_DEV_DIR/Toolchains/XcodeDefault.xctoolchain/usr"/*; do
        if [ "$(basename "$file")" != "bin" ]; then
            ln -s "$file" "$FAKE_DEV_DIR/Toolchains/XcodeDefault.xctoolchain/usr/"
        fi
    done
    for file in "$REAL_DEV_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin"/*; do
        ln -s "$file" "$FAKE_DEV_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/"
    done
    
    # Remove symlinked xcodebuild and lipo, and replace with our wrappers
    rm "$FAKE_DEV_DIR/usr/bin/xcodebuild"
    cat << 'EOF2' > "$FAKE_DEV_DIR/usr/bin/xcodebuild"
    #!/bin/bash
    exec "$REAL_DEV_DIR/usr/bin/xcodebuild" -IDEPackageSupportDisableManifestSandbox=YES -IDEPackageSupportDisablePluginExecutionSandbox=YES "$@"
    EOF2
    chmod +x "$FAKE_DEV_DIR/usr/bin/xcodebuild"

    # We need to wrap lipo in both places to ensure it intercepts correctly.
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
        echo "FAKE LIPO: out_file is $out_file" >&2
        dir_to_fix="$(dirname "$out_file")"
        echo "FAKE LIPO: dir_to_fix is $dir_to_fix" >&2
        ls -la "$dir_to_fix" >&2
        # Try to fix permissions all the way up to the build dir
        chmod -R +w "$dir_to_fix" || echo "FAKE LIPO: chmod failed on $dir_to_fix" >&2
        chmod -R +w "${dir_to_fix}/.." || true
        chmod -R +w "${dir_to_fix}/../.." || true
    fi
    exec "$REAL_DEV_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/lipo" "$@"
    EOF3
    )
    
    rm -f "$FAKE_DEV_DIR/usr/bin/lipo"
    echo "$LIPO_SCRIPT" > "$FAKE_DEV_DIR/usr/bin/lipo"
    chmod +x "$FAKE_DEV_DIR/usr/bin/lipo"
    
    rm -f "$FAKE_DEV_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/lipo"
    echo "$LIPO_SCRIPT" > "$FAKE_DEV_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/lipo"
    chmod +x "$FAKE_DEV_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/lipo"
    
    export DEVELOPER_DIR="$FAKE_DEV_DIR"

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
