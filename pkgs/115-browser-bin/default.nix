{
  lib,
  stdenv,
  autoPatchelfHook,
  dpkg,
  fetchurl,
  dbus,
  expat,
  glib,
  libidn2,
  alsa-lib,
  atk,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  gdk-pixbuf,
  libdrm,
  libxkbcommon,
  nspr,
  nss,
  pango,
  libglvnd,
  mesa,
  xorg,
  zlib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "browser-115-bin";
  version = "36.0.0";

  src = fetchurl {
    url = "https://down.115.com/client/115pc/lin/115br_v${finalAttrs.version}.deb";
    hash = "sha256-E5+0421/SPHheTF+WtK9ixKHnnHTxP+Z2iaGVmG0/Eg=";
  };

  privacy = fetchurl {
    url = "https://115.com/privacy.html";
    hash = "sha256-E9H4Dd4CJLQ6iJGc6wJ++SeAvGFnLlYoL5/Tw2UiG6Y=";
  };

  copyright = fetchurl {
    url = "https://115.com/copyright.html";
    hash = "sha256-z+JeTV2CNrO2gIn7xLVqqn2x0KVgkF8frwBLxeRTQkU=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
  ];

  buildInputs = [
    dbus
    expat
    glib
    libidn2
    alsa-lib
    atk
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    gdk-pixbuf
    libdrm
    libxkbcommon
    nspr
    nss
    pango
    libglvnd
    mesa
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libxcb
    xorg.libXcursor
    xorg.libXi
    xorg.libXrender
    xorg.libXScrnSaver
    zlib
    stdenv.cc.cc.lib
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    shopt -s nullglob
    for dir in usr opt; do
      if [ -e "$dir" ]; then
        cp -a "$dir" "$out/"
      fi
    done

    if [ -d "$out/usr/local/115Browser" ]; then
      mkdir -p "$out/opt/115"
      mv "$out/usr/local/115Browser" "$out/opt/115/"
      rmdir "$out/usr/local" 2>/dev/null || true
    fi

    if [ -f "$out/usr/share/applications/115Browser.desktop" ]; then
      substituteInPlace "$out/usr/share/applications/115Browser.desktop" \
        --replace-fail "/usr/local" "/opt/115"
    fi

    if [ -f "$out/opt/115/115Browser/115.sh" ]; then
      substituteInPlace "$out/opt/115/115Browser/115.sh" \
        --replace-fail "/usr/local" "/opt/115" \
        --replace-fail "/opt/115" "$out/opt/115"
    fi

    mkdir -p "$out/bin"
    cat > "$out/bin/115-browser" <<'EOF'
    #!/bin/sh
    set -eu

    APP_DIR="$out/opt/115/115Browser"
    APP_NAME="115Browser"
    APP_PATH="$APP_DIR/$APP_NAME"

    export LD_LIBRARY_PATH="$APP_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

    if [ ! -d "$APP_DIR" ]; then
      echo "Error: $APP_DIR not found!" >&2
      exit 1
    fi

    if [ ! -f "$APP_PATH" ]; then
      echo "Error: $APP_PATH not found!" >&2
      exit 1
    fi

    if [ ! -x "$APP_PATH" ]; then
      echo "Error: $APP_PATH not executable!" >&2
      exit 1
    fi

    cd "$APP_DIR"

    exec "$APP_PATH" "$@"
    EOF
    chmod +x "$out/bin/115-browser"

    install -Dm644 "$privacy" "$out/share/licenses/${finalAttrs.pname}/privacy.html"
    install -Dm644 "$copyright" "$out/share/licenses/${finalAttrs.pname}/copyright.html"

    runHook postInstall
  '';

  dontStrip = true;

  meta = {
    description = "115 Browser";
    homepage = "https://115.com/product_browser";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "115-browser";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
