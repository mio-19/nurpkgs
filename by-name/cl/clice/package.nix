{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  zlib,
  ncurses,
  libxml2,
}:

let
  version = "0.1.2026100708";

  platformAttrs =
    if stdenv.hostPlatform.system == "x86_64-linux" then {
      suffix = "x86_64-unknown-linux-gnu";
      hash = "sha256-/ZXiq3QcEXkKd8Y0Ff+aD9r33I3aNNT8vv1RNps4HDI=";
    } else if stdenv.hostPlatform.system == "aarch64-linux" then {
      suffix = "aarch64-unknown-linux-gnu";
      hash = "sha256-a+Kpr+bOfT1fu9A1VCnW8J2UCgQDWIRlwxLdAytfomI=";
    } else throw "Unsupported system: ${stdenv.hostPlatform.system}";
in
stdenv.mkDerivation {
  pname = "clice";
  inherit version;

  src = fetchzip {
    url = "https://github.com/clice-io/clice/releases/download/v${version}/clice-${version}.${platformAttrs.suffix}.tar.gz";
    hash = platformAttrs.hash;
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    zlib
    ncurses
    libxml2
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp -r * $out/
    runHook postInstall
  '';

  meta = with lib; {
    description = "Next-generation C++ language server built on LLVM/Clang";
    homepage = "https://github.com/clice-io/clice";
    changelog = "https://docs.clice.io/clice/";
    license = licenses.asl20;
    maintainers = [ ];
    mainProgram = "clice";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
