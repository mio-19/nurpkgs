{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeBinaryWrapper,
  acl,
  libxcb-util,
  xorg,
}:

rustPlatform.buildRustPackage rec {
  pname = "ego";
  version = "1.1.7-unstable-20251231";

  src = fetchFromGitHub {
    owner = "mio-19";
    repo = "ego";
    rev = "b08502d7a19e26edbfab75774f69cf02cc3883ea"; # version;
    hash = "sha256-cKZwZouEA92y9HsHAkQVhJjBiZIBJODZRqFGsQEMbaM=";
  };

  buildInputs = [
    acl
    libxcb-util
  ];

  nativeBuildInputs = [ makeBinaryWrapper ];

  cargoHash = "sha256-8CQUyUEh5yzuECol+EqO+I+HNJ28fmeIf2AsnTakEfg=";

  # requires access to /root
  checkFlags = [
    "--skip tests::test_check_user_homedir"
  ];

  postInstall = ''
    wrapProgram $out/bin/ego --prefix PATH : ${lib.makeBinPath [ xorg.xhost ]}
  '';

  meta = {
    description = "Run Linux desktop applications under a different local user";
    homepage = "https://github.com/intgr/ego";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ dit7ya ];
    mainProgram = "ego";
  };
}
