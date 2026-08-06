{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  util-linux,
  openssl,
  cacert,
  variant ? "all",
  extraConfigureFlags ? [ ],
  enableLto ? true,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "wolfssl-${variant}";
  version = "5.7.2";

  src = fetchFromGitHub {
    owner = "wolfSSL";
    repo = "wolfssl";
    rev = "refs/tags/v${finalAttrs.version}-stable";
    hash = "sha256-VTMVgBSDL6pw1eEKnxGzTdyQYWVbMd3mAnOnpAOKVhk=";
  };

  postPatch = ''
    patchShebangs ./scripts
    sed -i -e'2s/.*/exit 77/' scripts/ocsp-stapling.test
    substituteInPlace scripts/ocsp-stapling2.test \
      --replace '"linux-gnu"' '"linux-"'
  '';

  configureFlags =
    [
      "--enable-${variant}"
      "--enable-reproducible-build"
    ]
    ++ lib.optionals (variant == "all") [
      "--enable-pkcs11"
      "--enable-writedup"
      "--enable-base64encode"
    ]
    ++ [
      "--enable-bigcache"
      "--enable-sp=yes${
        lib.optionalString (stdenv.hostPlatform.isx86_64 || stdenv.hostPlatform.isAarch) ",asm"
      }"
      "--enable-sp-math-all"
      "--enable-harden"
    ]
    ++ lib.optionals (stdenv.hostPlatform.isx86_64) [
      "--enable-intelasm"
      "--enable-aesni"
    ]
    ++ extraConfigureFlags;

  env.NIX_CFLAGS_COMPILE = lib.optionalString enableLto "-flto";
  env.NIX_LDFLAGS_COMPILE = lib.optionalString enableLto "-flto";

  outputs = [
    "dev"
    "doc"
    "lib"
    "out"
  ];

  nativeBuildInputs = [
    autoreconfHook
    util-linux
  ];

  doCheck = false;

  nativeCheckInputs = [
    openssl
    cacert
  ];

  postInstall = ''
    moveToOutput bin/wolfssl-config "$dev"
    mkdir -p "$out"
  '';

  meta = with lib; {
    description = "A small, fast, portable implementation of TLS/SSL";
    mainProgram = "wolfssl-config";
    homepage = "https://www.wolfssl.com/";
    platforms = platforms.all;
    license = licenses.gpl2Plus;
  };
})
