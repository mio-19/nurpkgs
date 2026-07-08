{
  lib,
  fetchurl,
  appimageTools,
}:
let
  pname = "beam-studio";
  version = "2.6.8-stable";

  src = fetchurl {
    url = "https://beamstudio.s3.amazonaws.com/linux-22.04/Beam%20Studio-2.6.8.AppImage";
    hash = "sha256-+NNeAThprCd+1WE7aVqlkCEk4rLmKN0aD5RykRkHOa8=";
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };

in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/beam-studio.desktop $out/share/applications/beam-studio.desktop
    cp -r ${appimageContents}/usr/share/icons $out/share
    substituteInPlace $out/share/applications/beam-studio.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=beam-studio' \
      --replace-fail 'Icon=beam-studio' 'Icon=beam-studio'
  '';

  meta = {
    description = "Beam Studio";
    homepage = "https://github.com/flux3dp/beam-studio";
    license = lib.licenses.agpl3Only;
    maintainers = [ ];
    mainProgram = "beam-studio";
    platforms = lib.platforms.linux;
  };
}
