{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "payload-dumper-go";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "ssut";
    repo = "payload-dumper-go";
    rev = "1.3.0";
    hash = "";
  };

  vendorHash = "";

  meta = with lib; {
    description = "An Android OTA payload dumper written in Go";
    homepage = "https://github.com/ssut/payload-dumper-go";
    license = licenses.asl20;
    maintainers = [ ];
    mainProgram = "payload-dumper-go";
  };
}
