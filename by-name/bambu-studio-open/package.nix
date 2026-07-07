{
  bambu-studio,
  stdenv,
  lib,
  cmake,
  ninja,
  pkg-config,
  fetchFromGitHub,
  openssl,
  uthash,
  git,
  zlib,
  curl,
}:

let
  bambuStudioVersion = bambu-studio.version;
  obnVersion =
    let
      parts = lib.splitString "." bambuStudioVersion;
      prefix = lib.concatStringsSep "." (lib.take 3 parts);
    in
    "${prefix}.99";

  mosquitto-src = fetchFromGitHub {
    owner = "eclipse";
    repo = "mosquitto";
    rev = "v2.1.2";
    hash = "sha256-Zl55yjuzQY2fyaKs/zLaJ7a3OONKTDQPaT+DpPURdZI=";
  };

  cjson-src = fetchFromGitHub {
    owner = "DaveGamble";
    repo = "cJSON";
    rev = "v1.7.18";
    hash = "sha256-UgUWc/+Zie2QNijxKK5GFe4Ypk97EidG8nTiiHhn5Ys=";
  };

  miniz-src = fetchFromGitHub {
    owner = "richgel999";
    repo = "miniz";
    rev = "a4264837ae37384b1d7a205a6732db322f0f3769";
    hash = "sha256-BgPYhQAdwPx5R/BIN/Mt3bm5AaikycGClEedWFw9COk=";
  };

  open-bamboo-networking = stdenv.mkDerivation {
    pname = "open-bamboo-networking";
    version = "0-unstable-2025-07-07";

    src = fetchFromGitHub {
      owner = "ClusterM";
      repo = "open-bamboo-networking";
      rev = "b6636ad34893487cc47f144a5e66d4e8b79bd027";
      hash = "sha256-u2BHI0vD9mxB0P21sCVm6goI8WczDE+/J747YDaXV7Q=";
      fetchSubmodules = false;
    };

    nativeBuildInputs = [
      cmake
      ninja
      pkg-config
      git
    ];

    buildInputs = [
      openssl
      uthash
      zlib
      curl
    ];

    postUnpack = ''
      rm -rf "$sourceRoot/third_party/miniz"
      cp -r ${miniz-src} "$sourceRoot/third_party/miniz"
      chmod -R u+w "$sourceRoot/third_party/miniz"
    '';

    cmakeFlags = [
      (lib.cmakeFeature "OBN_VERSION" obnVersion)
      (lib.cmakeBool "OBN_PATCH_CLIENT_CONF" false)
      (lib.cmakeBool "OBN_RELEASE" true)
    ];

    preConfigure = ''
      cp -r ${mosquitto-src} $TMPDIR/mosquitto-src
      chmod -R u+w $TMPDIR/mosquitto-src
      cp -r ${cjson-src} $TMPDIR/cjson-src
      chmod -R u+w $TMPDIR/cjson-src

      cmakeFlagsArray+=(
        "-DFETCHCONTENT_SOURCE_DIR_ECLIPSE_MOSQUITTO=$TMPDIR/mosquitto-src"
        "-DFETCHCONTENT_SOURCE_DIR_CJSON=$TMPDIR/cjson-src"
      )
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib
      find . -maxdepth 2 \( -name "libbambu_networking.so" -o -name "libBambuSource.so" \) \
        -exec cp {} $out/lib/ \;
      runHook postInstall
    '';

    meta = {
      description = "Open-source drop-in replacement for Bambu Studio's proprietary bambu_networking plugin";
      homepage = "https://github.com/ClusterM/open-bamboo-networking";
      license = lib.licenses.gpl3Plus;
      platforms = lib.platforms.linux;
    };
  };

in
bambu-studio.overrideAttrs (oldAttrs: {
  pname = "bambu-studio-open";

  patches = (oldAttrs.patches or [ ]) ++ [ ./obn.patch ];

  postPatch = (oldAttrs.postPatch or "") + ''
    substituteInPlace src/slic3r/Utils/NetworkAgent.cpp \
      --replace-fail "@obn_plugin_path@" "${open-bamboo-networking}/lib/libbambu_networking.so" \
      --replace-fail "@obn_bambu_source_path@" "${open-bamboo-networking}/lib/libBambuSource.so"
  '';

  meta = oldAttrs.meta // {
    description = "Bambu Studio with open-bamboo-networking (FOSS networking plugin)";
    license = lib.licenses.agpl3Plus;
    maintainers = [ ];
  };
})
