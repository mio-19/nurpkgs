{
  lib,
  buildMozillaMach,
  cacert,
  curl,
  fetchFromGitHub,
  fetchurl,
  git,
  libdbusmenu-gtk3 ? null,
  runtimeShell,
  thunderbirdPackages,
  unzip,
  stdenv,
  linkFarmFromDrvs,
  fetchhg,
}:

let
  thunderbird-unwrapped = thunderbirdPackages.thunderbird-140;

  version = "140.5.0esr";
  majVer = lib.versions.major version;

  betterbird-patches-plain = fetchFromGitHub {
    owner = "Betterbird";
    repo = "thunderbird-patches";
    rev = "${version}-bb14";
    hash = "sha256-Hzdm8xpoEqV9BsqW235JrLalq5sUNcvp/QMjU3aSuxI=";
  };

  remote-patch-data = lib.importJSON ./patchdata.json;

  remote-patches = map ({name, url, hash}:
    fetchurl {
      inherit name url hash;
    }
  ) remote-patch-data;

  remote-patches-folder = linkFarmFromDrvs "betterbird-remote-patches" remote-patches;

  betterbird-patches = betterbird-patches-plain;
  # betterbird-patches = fetchFromGitHub {
  #   owner = "Betterbird";
  #   repo = "thunderbird-patches";
  #   rev = "${version}-bb14";
  #   postFetch = ''
  #     export PATH=${lib.makeBinPath [ curl ]}:$PATH
  #     export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
  #
  #     echo "Retrieving external patches"
  #     cd $out/${majVer}
  #
  #     # Create directories for external patches
  #     mkdir -p external
  #
  #     # Download external patches for Mozilla repo (series-moz)
  #     if [ -f series-moz ]; then
  #       echo "Processing series-moz for Mozilla external patches"
  #       grep " # " series-moz | grep -v "^#" | while read line || [[ -n $line ]]; do
  #         patch=$(echo "$line" | cut -f1 -d'#' | sed 's/ *$//')
  #         url=$(echo "$line" | cut -f2 -d'#' | sed 's/^ *//')
  #         if [[ -n "''${patch// }" ]] && [[ -n "''${url// }" ]]; then
  #           url=$(echo "$url" | sed 's/\/rev\//\/raw-rev\//')
  #           echo "Downloading $patch from $url"
  #           curl -L -f "$url" -o external/$patch
  #         fi
  #       done
  #     fi
  #
  #     # Download external patches for comm repo (series)
  #     if [ -f series ]; then
  #       echo "Processing series for comm external patches"
  #       grep " # " series | grep -v "^#" | while read line || [[ -n $line ]]; do
  #         patch=$(echo "$line" | cut -f1 -d'#' | sed 's/ *$//')
  #         url=$(echo "$line" | cut -f2 -d'#' | sed 's/^ *//')
  #         if [[ -n "''${patch// }" ]] && [[ -n "''${url// }" ]]; then
  #           url=$(echo "$url" | sed 's/\/rev\//\/raw-rev\//')
  #           echo "Downloading $patch from $url"
  #           curl -L -f "$url" -o external/$patch
  #         fi
  #       done
  #     fi
  #   '';
  #   hash = "sha256-b7N+r7ZUk2WdUC3KWyCnLQy9Jg9p4740WpizbvlWVeM=";
  # };
  # Fetch and extract comm subdirectory
  # https://github.com/Betterbird/thunderbird-patches/blob/main/140/140.sh
  # comm-source = fetchurl {
  #   url = "https://hg-edge.mozilla.org/releases/comm-esr${majVer}/archive/6a3011b7161c6f3a36d5116f2608d51b19fb4d58.zip";
  #   hash = "sha256-K7BBwMmePC4MoD6xllklbh58I1a65fajO846qRDacEk=";
  # };
  comm-source = fetchhg {
    name = "comm-source";
    url = "https://hg.mozilla.org/releases/comm-esr140";
    rev = "6a3011b7161c6f3a36d5116f2608d51b19fb4d58";
    hash = "sha256-w8KLdxw3r/E3dFM9ejRajMPTsAQ3VRFzF0HBve33JFk=";
  };
in
(
  (buildMozillaMach {
    pname = "betterbird";
    inherit version;

    # Keep binaryName as "thunderbird" so --with-app-name=thunderbird is passed
    # The betterbird patches change the BINARY variable to "betterbird" while keeping MOZ_APP_NAME=thunderbird
    applicationName = "Betterbird";
    binaryName = "thunderbird";
    application = "comm/mail";
    branding = "comm/mail/branding/betterbird";
    inherit (thunderbird-unwrapped) extraPatches;

    # src = fetchurl {
    #   # https://download.cdn.mozilla.net/pub/thunderbird/releases/
    #   #url = "mirror://mozilla/thunderbird/releases/${version}/source/thunderbird-${version}.source.tar.xz";
    #   # https://github.com/Betterbird/thunderbird-patches/blob/main/140/140.sh
    #   url = "https://hg-edge.mozilla.org/releases/mozilla-esr${majVer}/archive/558705980ca9db16de0564b5a6031b5d6e0a7efe.zip";
    #   hash = "sha256-f2qBCXFW7EGrWUORB3+YYEzYYpnlrJ71Gn0EKO2+K00=";
    # };
    src = fetchhg {
      name = "mozilla-source";
      url = "https://hg.mozilla.org/releases/mozilla-esr140";
      rev = "558705980ca9db16de0564b5a6031b5d6e0a7efe";
      hash = "sha256-IS/rn7qvnmEqMh8IRsCFNH5Y0C/7KXGDAuPPcjCqcFc=";
    };

    unpackPhase = ''
      runHook preUnpack

      mozillaDir="$PWD/mozillaDir"
      mkdir "$mozillaDir"
      cp -r "$src" "$mozillaDir"

      cp -r ${comm-source} "$mozillaDir/comm"

      # Change into the source directory
      cd "$mozillaDir"
      chmod -R +w .

      # Set sourceRoot for the build
      sourceRoot="$PWD"

      runHook postUnpack
    '';

    extraPostPatch = thunderbird-unwrapped.extraPostPatch or "" + /* bash */ ''
      PATH=$PATH:${lib.makeBinPath [ git ]}
      patches=$(mktemp -d)
      for dir in branding bugs features misc; do
        if [ -d ${betterbird-patches}/${majVer}/$dir ]; then
          cp -r ${betterbird-patches}/${majVer}/$dir/*.patch $patches/
        fi
      done
      # Copy external patches
      cp ${remote-patches-folder}/*.patch $patches/

      cp ${betterbird-patches}/${majVer}/series* $patches/
      chmod -R +w $patches

      cd $patches
      # fix FHS paths to libdbusmenu (only on non-Darwin when libdbusmenu-gtk3 is available)
      ${lib.optionalString (!stdenv.hostPlatform.isDarwin && libdbusmenu-gtk3 != null) ''
        substituteInPlace 12-feature-linux-systray.patch \
          --replace-fail "/usr/include/libdbusmenu-glib-0.4/" "${lib.getDev libdbusmenu-gtk3}/include/libdbusmenu-glib-0.4/" \
          --replace-fail "/usr/include/libdbusmenu-gtk3-0.4/" "${lib.getDev libdbusmenu-gtk3}/include/libdbusmenu-gtk3-0.4/"
      ''}
      cd -

      chmod -R +w dom/base/test/gtest/

      function trim() {
          local var="$1"
          # remove leading whitespace characters
          var="''${var#"''${var%%[![:space:]]*}"}"
          # remove trailing whitespace characters
          var="''${var%"''${var##*[![:space:]]}"}"
          printf '%s' "$var"
      }

      function applyPatches() {
        declare seriesFile="$1" srcRoot="$2"
        declare -a patchLines=()
        mapfile -t patchLines <"$seriesFile"
        declare patch=""
        for patch in "''${patch[@]}"; do
          patch="''${patch%%#*}"
          patch="$(trim patch)"
          if [[ $patch == "" ]]; then
            continue
          fi

          # requires vendored icu, fails to link with our icu
          # feature-506064 depends on those icu patches
          if [[ $patch == 14-feature-regexp-searchterm.patch || $patch == 14-feature-regexp-searchterm-moz.patch || $patch == feature-506064-match-diacritics.patch || $patch == feature-506064-match-diacritics-moz.patch ]]; then
            continue
          fi
          (
            cd -- "$srcRoot"
            echo "Applying patch $patch in $PWD"
            git apply -p1 -v --allow-empty < $patches/$patch
          )
        done
      }

      applyPatches series-moz .
      applyPatches series comm
    '';

    extraBuildInputs = lib.optionals (!stdenv.hostPlatform.isDarwin && libdbusmenu-gtk3 != null) [
      libdbusmenu-gtk3
    ];

    # Additional mozconfig options from official Betterbird build
    extraConfigureFlags = [
      "--with-unsigned-addon-scopes=app,system"
      "--allow-addon-sideload"
    ]
    ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [
      "--enable-default-toolkit=cairo-gtk3-wayland"
    ]
    ++ [
      "--without-wasm-sandboxed-libraries"
    ];

    meta = with lib; {
      description = "Betterbird is a fine-tuned version of Mozilla Thunderbird, Thunderbird on steroids, if you will";
      homepage = "https://www.betterbird.eu/";
      mainProgram = "betterbird";
      maintainers = with maintainers; [ SuperSandro2000 ];
      inherit (thunderbird-unwrapped.meta)
        platforms
        broken
        license
        ;
    };
  }).override
  {
    crashreporterSupport = false; # not supported
    geolocationSupport = false;
    webrtcSupport = false;

    pgoSupport = false; # console.warn: feeds: "downloadFee d: network connection unavailable"

    inherit (thunderbird-unwrapped.passthru) icu73;
  }
).overrideAttrs
  (oldAttrs: {
    # Remove wasi-sysroot flag - not available in Betterbird/Thunderbird 140 configuration
    configureFlags = lib.filter (
      flag: !lib.hasPrefix "--with-wasi-sysroot=" flag
    ) oldAttrs.configureFlags;

    patches = [];

    # Environment variables from official build
    preConfigure = (oldAttrs.preConfigure or "") + ''
      export MOZ_APP_REMOTINGNAME=eu.betterbird.Betterbird
      export MOZ_REQUIRE_SIGNING=
      export MOZ_REQUIRE_ADDON_SIGNING=0
    '';

    postInstall =
      oldAttrs.postInstall or ""
      + lib.optionalString (!stdenv.hostPlatform.isDarwin) ''
        mkdir -p $out/lib/betterbird
        mv $out/lib/thunderbird/* $out/lib/betterbird/
        rmdir $out/lib/thunderbird
        rm $out/bin/thunderbird
        ln -srf $out/lib/betterbird/betterbird $out/bin/betterbird
      ''
      + lib.optionalString stdenv.hostPlatform.isDarwin ''
        # On macOS, the build creates Betterbird.app because applicationName = "Betterbird"
        # The wrapper will look for it at Applications/Betterbird.app
        # No need to rename since it's already correctly named
        # Just ensure the binary symlink exists (may already be created by buildMozillaMach)
        mkdir -p $out/bin
        ln -sf $out/Applications/Betterbird.app/Contents/MacOS/betterbird $out/bin/betterbird
      '';

    doInstallCheck = false;

    passthru = oldAttrs.passthru // {
      inherit betterbird-patches betterbird-patches-plain remote-patches-folder comm-source;
    };
  })
