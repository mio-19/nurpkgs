{
  lib,
  stdenvNoCC,
  python3,
  git,
  cacert,
  cmake,
  ninja,
  openssl,
  zlib,
  autoconf,
  libtool,
  automake,
  yasm,
  nasm,
  pkg-config,
  unzip,
  meson,
  fetchzip,
  writableTmpDirAsHomeHook,
}:

# NOTE: Building TelegramSwift (the native Telegram for macOS client) from source
# is notoriously complex in a pure Nix environment. It relies heavily on Xcode,
# Swift Package Manager (which requires network access during the build), and
# specific code-signing setups.
#
# This derivation provides a foundation, but achieving a fully pure, functional
# build will likely require:
# 1. Impure builds (sandbox = false) to allow Xcode and SPM network access.
# 2. Or, a complex translation of Swift Package Manager dependencies into Nix.
# 3. Supplying valid `api_id` and `api_hash` credentials.

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "telegram-mac";
  version = "10.14"; # Update to the latest desired version

  ffmpegSrc = fetchzip {
    url = "https://ffmpeg.org/releases/ffmpeg-7.1.tar.xz";
    hash = "sha256-cNb7sIx7YIoVcamG6/cCFAdELSAm/N0OFBaJ1imJDQk=";
  };

  src = stdenvNoCC.mkDerivation {
    name = "telegram-mac-source";
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-hp1cI+6dbAWrgfgq5nNUScyDDe48E8k7GmaGWxyTCvM="; # Will need to be updated after first run

    nativeBuildInputs = [
      git
      cacert
      writableTmpDirAsHomeHook
    ];

    buildCommand = ''
      git config --global url."https://github.com/".insteadOf "git@github.com:"
      git config --global url."https://gitlab.com/".insteadOf "git@gitlab.com:"

      git clone https://github.com/overtake/TelegramSwift.git $out
      cd $out
      git checkout 579cebbf0c01fd41b712eff3647fa7f69db9665d
      git submodule update --init --recursive
      rm -rf .git
    '';
  };

  nativeBuildInputs = [
    python3
    cmake
    ninja
    openssl
    zlib
    autoconf
    libtool
    automake
    yasm
    nasm
    pkg-config
    unzip
    meson
    writableTmpDirAsHomeHook
  ];

  # Using xcodebuild directly usually requires the environment to have Xcode available.
  # This requires setting `sandbox = false` in your nix.conf for Darwin.
  __noChroot = true; # Hint for Hydra/Nix to disable sandbox if possible
  dontUseCmakeConfigure = true;
  dontUseMesonConfigure = true;

  buildPhase = ''
    runHook preBuild

    # Copy FFmpeg source
    mkdir -p submodules/telegram-ios/submodules/ffmpeg/Sources/FFMpeg/ffmpeg-7.1
    cp -r ${finalAttrs.ffmpegSrc}/* submodules/telegram-ios/submodules/ffmpeg/Sources/FFMpeg/ffmpeg-7.1/

    # Allow scripts to find xcrun and xcodebuild on the host
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
    export PATH=$PATH:/usr/bin:/bin:/usr/sbin:/sbin
    
    # CoreFoundation uses the user database for home dir, override it:
    export CFFIXED_USER_HOME=$HOME

    # Telegram for macOS requires framework configuration first
    sed -i 's/no/yes/g' scripts/rebuild || true

    # Fix CMake 3.5 compatibility for Mozjpeg
    sed -i 's/cmake_minimum_required(VERSION .*/cmake_minimum_required(VERSION 3.5)/g' submodules/telegram-ios/third-party/mozjpeg/mozjpeg/CMakeLists.txt || true

    # Fix libwebp ZIP extraction (Nix GNU tar does not support ZIP, use unzip)
    sed -i 's/tar -xzf "$SOURCE_ARCHIVE" --directory "$OUT_DIR"/unzip -q "$SOURCE_ARCHIVE" -d "$OUT_DIR"/g' core-xprojects/libwebp/libwebp/build*.sh || true

    # Fix webrtc build script to correctly copy source directory contents (avoids missing CMakeLists.txt)
    sed -i 's/cp -R \$SOURCE_DIR \$BUILD_DIR/cp -R "$SOURCE_DIR"\/. "$BUILD_DIR"\//g' core-xprojects/webrtc/webrtc/build.sh || true

    # Fix Mozjpeg build script for GNU cp
    sed -i 's/mozjpeg\/" "''${BUILD_DIR}build\/"/mozjpeg\/"\/. "''${BUILD_DIR}build\/"/g' core-xprojects/Mozjpeg/Mozjpeg/build.sh || true

    # Fix webrtc libopus include path
    sed -i 's/libopus\/build\/libopus\/include\/opus/libopus\/build\/libopus\/include\/opus\/include/g' core-xprojects/webrtc/webrtc.xcodeproj/project.pbxproj || true

    # Fix the custom pkg-config wrapper to parse custom paths properly when ffmpeg prepends them
    cat > submodules/telegram-ios/submodules/ffmpeg/Sources/FFMpeg/pkg-config <<'EOF'
    #!/bin/sh
    LIBOPUS_PATH=""
    LIBVPX_PATH=""
    LIBDAV1D_PATH=""
    CMD=""
    NAME=""

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --libopus_path) LIBOPUS_PATH="$2"; shift 2 ;;
            --libvpx_path) LIBVPX_PATH="$2"; shift 2 ;;
            --libdav1d_path) LIBDAV1D_PATH="$2"; shift 2 ;;
            --version|--exists|--cflags|--libs) CMD="$1"; shift 1 ;;
            --print-errors) shift 1 ;;
            zlib*|opus*|vpx*|dav1d*) NAME="$1"; shift 1 ;;
            *) shift 1 ;;
        esac
    done

    if [ "$CMD" == "--version" ]; then
        echo "0.29.2"
        exit 0
    elif [ "$CMD" == "--exists" ]; then
        case "$NAME" in
            zlib*|opus*|vpx*|dav1d*) exit 0 ;;
            *) exit 1 ;;
        esac
    elif [ "$CMD" == "--cflags" ]; then
        case "$NAME" in
            zlib*) echo "" ;;
            opus*) echo "-I$LIBOPUS_PATH/include/opus/include -I$LIBOPUS_PATH/include/opus" ;;
            vpx*) echo "-I$LIBVPX_PATH/include" ;;
            dav1d*) echo "-I$LIBDAV1D_PATH/include" ;;
            *) exit 1 ;;
        esac
        exit 0
    elif [ "$CMD" == "--libs" ]; then
        case "$NAME" in
            zlib*) echo "-lz" ;;
            opus*) echo "-L$LIBOPUS_PATH/lib -lopus" ;;
            vpx*) echo "-L$LIBVPX_PATH/lib -lVPX" ;;
            dav1d*) echo "-L$LIBDAV1D_PATH/lib -ldav1d" ;;
            *) exit 1 ;;
        esac
        exit 0
    else
        exit 1
    fi
    EOF
    chmod +x submodules/telegram-ios/submodules/ffmpeg/Sources/FFMpeg/pkg-config

    # Run the setup script
    sh scripts/configure_frameworks.sh

    set -x
    pwd

    sed -i '/MetalFunctions.metal in Sources/d' Telegram.xcodeproj/project.pbxproj || true

    # Disable SwiftPM sandboxing by passing IDE flags to xcodebuild directly
    xcodebuild -workspace Telegram-Mac.xcworkspace \
               -scheme Telegram \
               -configuration Release \
               -derivedDataPath build \
               -clonedSourcePackagesDirPath build/swiftpm \
               -IDEPackageSupportDisableManifestSandbox=YES \
               -IDEPackageSupportDisablePluginExecutionSandbox=YES \
               CODE_SIGN_IDENTITY="" \
               CODE_SIGNING_REQUIRED=NO \
               CODE_SIGNING_ALLOWED=NO

    # Manually compile metal shaders using the working compiler
    /Users/Shared/Metal.xctoolchain/usr/bin/metal -c -target air64-apple-macos10.13 Telegram-Mac/MetalFunctions.metal -o MetalFunctions.air || true
    /Users/Shared/Metal.xctoolchain/usr/bin/metallib MetalFunctions.air -o default.metallib || true
    cp default.metallib build/Build/Products/Release/Telegram.app/Contents/Resources/default.metallib || true

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    cp -r build/Build/Products/Release/Telegram.app $out/Applications/

    runHook postInstall
  '';

  meta = {
    description = "Telegram for macOS (Native Swift Client)";
    longDescription = ''
      The native macOS Telegram client, built from source. 
      Warning: Building this requires Xcode and is generally not pure.
    '';
    homepage = "https://github.com/overtake/TelegramSwift";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.darwin;
  };
})
