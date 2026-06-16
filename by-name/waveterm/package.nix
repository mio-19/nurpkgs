{
  lib,
  stdenv,
  fetchFromGitHub,
  buildGoModule,
  buildNpmPackage,
  fetchNpmDeps,
  runCommand,
  nodejs_22,
  electron_41,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
}:

let
  pname = "waveterm";
  version = "0.14.5";

  electron = electron_41;
  nodejs = nodejs_22;

  src = fetchFromGitHub {
    owner = "wavetermdev";
    repo = "waveterm";
    tag = "v${version}";
    hash = "sha256-SUcvIpM+++qfyAlwUPSGVz2OUJXPe0bsefcjUKYUF/g=";
  };

  # waveterm uses a fixed build time string baked into the binaries; pin it for reproducibility.
  buildTime = "0";

  hostGoArch =
    {
      x86_64-linux = "amd64";
      aarch64-linux = "arm64";
    }
    .${stdenv.hostPlatform.system}
      or (throw "waveterm: unsupported system ${stdenv.hostPlatform.system}");
  hostNormArch = if hostGoArch == "amd64" then "x64" else hostGoArch;

  # The Go backend: the wavesrv server (CGO + sqlite) and the wsh helper
  # (cross-compiled, pure Go, for every platform Wave can connect to).
  backend = buildGoModule {
    pname = "${pname}-backend";
    inherit version src;

    vendorHash = "sha256-EyDS/AB56+yE54XhwnQhalNPZwMM/Hp2kWQN824yq0k=";

    # wshrpc/typescript bindings and schema are committed in the tree, so the
    # codegen step can be skipped and we only compile the binaries.
    buildPhase = ''
      runHook preBuild

      mkdir -p dist/bin

      echo "building wavesrv (${hostNormArch})"
      CGO_ENABLED=1 go build \
        -tags "osusergo,sqlite_omit_load_extension" \
        -ldflags "-X main.BuildTime=${buildTime} -X main.WaveVersion=${version}" \
        -o dist/bin/wavesrv.${hostNormArch} \
        cmd/server/main-server.go

      buildWsh() {
        local goos="$1" goarch="$2" ext="$3"
        local narch="$goarch"
        [ "$goarch" = "amd64" ] && narch="x64"
        echo "building wsh ($goos/$narch)"
        CGO_ENABLED=0 GOOS="$goos" GOARCH="$goarch" go build \
          -ldflags "-s -w -X main.BuildTime=${buildTime} -X main.WaveVersion=${version}" \
          -o "dist/bin/wsh-${version}-$goos.$narch$ext" \
          cmd/wsh/main-wsh.go
      }

      buildWsh darwin arm64 ""
      buildWsh darwin amd64 ""
      buildWsh linux arm64 ""
      buildWsh linux amd64 ""
      buildWsh linux mips ""
      buildWsh linux mips64 ""
      buildWsh windows amd64 ".exe"
      buildWsh windows arm64 ".exe"

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r dist/bin $out/bin
      runHook postInstall
    '';

    doCheck = false;
  };

  # The tsunami "scaffold" ships a small node_modules (tailwind CLI) that Wave
  # uses at runtime to build user widgets. It is installed from its own
  # package.json (no lockfile upstream), so we vendor a generated one.
  scaffoldSrc = runCommand "${pname}-scaffold-src" { } ''
    mkdir -p $out
    cp ${./tsunami-scaffold-package.json} $out/package.json
    cp ${./tsunami-scaffold-package-lock.json} $out/package-lock.json
  '';

  scaffoldNpmDeps = fetchNpmDeps {
    name = "${pname}-tsunami-scaffold-npm-deps";
    src = scaffoldSrc;
    hash = "sha256-PU6pKf+IlULH1JDjfCfeM2M+tEwPirr7zLlo9lTEtMU=";
  };
in
buildNpmPackage {
  inherit pname version src;

  npmDeps = fetchNpmDeps {
    inherit src;
    name = "${pname}-npm-deps";
    hash = "sha256-YkRfTZwjIet6CWTtqG8X9LjoCOjHO+L2uHHtBlr7tao=";
  };

  inherit nodejs;
  makeCacheWritable = true;

  # Native deps ship as prebuilt platform packages; rebuilding only pulls in the
  # docs workspace's old sharp, which tries to download libvips from the network.
  npmRebuildFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [
    makeWrapper
    copyDesktopItems
  ];

  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
    # postinstall runs `electron-builder install-app-deps`, which needs network.
    WAVETERM_SKIP_APP_DEPS = "1";
  };

  dontNpmBuild = true;

  # Running a shared electron against an app.asar leaves `app.isPackaged` false,
  # which would put Wave in "dev" mode (wrong data dir, dev features). This is a
  # production build, so force it.
  postPatch = ''
    substituteInPlace emain/emain-platform.ts \
      --replace-fail "const isDev = !app.isPackaged;" "const isDev = false;"
  '';

  buildPhase = ''
    runHook preBuild

    # 1. Build the renderer/main/preload bundles.
    npm run build:prod

    # 2. Build the tsunami frontend and assemble the runtime scaffold.
    pushd tsunami/frontend
    npm run build

    rm -rf scaffold
    mkdir -p scaffold
    cp ../templates/package.json.tmpl scaffold/package.json
    cp ${./tsunami-scaffold-package-lock.json} scaffold/package-lock.json

    scaffoldCache="$TMPDIR/scaffold-npm-cache"
    cp -r ${scaffoldNpmDeps} "$scaffoldCache"
    chmod -R u+w "$scaffoldCache"

    pushd scaffold
    npmDeps="$scaffoldCache" "$prefetchNpmDeps" --fixup-lockfile package-lock.json
    npm_config_cache="$scaffoldCache" npm ci --offline --ignore-scripts
    popd

    mv scaffold/node_modules scaffold/nm
    cp -r dist scaffold/
    mkdir -p scaffold/dist/tw
    cp ../templates/*.go.tmpl scaffold/
    cp ../templates/tailwind.css scaffold/
    cp ../templates/gitignore.tmpl scaffold/.gitignore
    cp src/element/*.tsx scaffold/dist/tw/
    cp ../ui/*.go scaffold/dist/tw/
    cp ../engine/errcomponent.go scaffold/dist/tw/
    popd

    rm -rf dist/tsunamiscaffold
    cp -r tsunami/frontend/scaffold dist/tsunamiscaffold
    cp tsunami/templates/empty-gomod.tmpl dist/tsunamiscaffold/go.mod

    # 3. Drop in the schema and the Go binaries that electron-builder expects.
    rm -rf dist/schema
    cp -r schema dist/schema

    mkdir -p dist/bin
    cp -r ${backend}/bin/. dist/bin/
    chmod -R u+w dist/bin

    # 4. Package the unpacked app directory against the nixpkgs electron.
    cp -r ${electron.dist} electron-dist
    chmod -R u+w electron-dist

    ${nodejs}/bin/node node_modules/electron-builder/out/cli/cli.js \
      --dir \
      -c electron-builder.config.cjs \
      -p never \
      -c.electronDist=electron-dist \
      -c.electronVersion=${electron.version} \
      -c.npmRebuild=false

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/waveterm
    cp -r make/*-unpacked/resources $out/share/waveterm/resources

    makeWrapper ${lib.getExe electron} $out/bin/waveterm \
      --add-flags $out/share/waveterm/resources/app.asar \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=UseOzonePlatform,WaylandWindowDecorations}}" \
      --set-default ELECTRON_IS_DEV 0 \
      --inherit-argv0

    for size in 16 32 48 64 128 256 512; do
      install -Dm644 "build/icons/''${size}x''${size}.png" \
        "$out/share/icons/hicolor/''${size}x''${size}/apps/waveterm.png"
    done

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "waveterm";
      exec = "waveterm %U";
      icon = "waveterm";
      desktopName = "Wave";
      genericName = "Terminal";
      comment = "Open-source, cross-platform terminal for seamless workflows";
      categories = [
        "Development"
        "Utility"
        "TerminalEmulator"
      ];
      keywords = [
        "developer"
        "terminal"
        "emulator"
      ];
      startupWMClass = "waveterm";
    })
  ];

  meta = {
    description = "Open-source, cross-platform terminal for seamless workflows (built from source)";
    homepage = "https://www.waveterm.dev";
    changelog = "https://github.com/wavetermdev/waveterm/releases/tag/v${version}";
    license = lib.licenses.asl20;
    mainProgram = "waveterm";
    maintainers = [ ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
