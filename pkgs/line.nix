{
  lib,
  mkWindowsAppNoCC,
  wine,
  fetchurl,
  makeDesktopItem,
  makeDesktopIcon,
  copyDesktopItems,
  copyDesktopIcons,
}:
mkWindowsAppNoCC rec {
  inherit wine;

  pname = "line";
  version = "9.2.0"; # :version:

  # https://community.chocolatey.org/packages/line#files
  src = fetchurl {
    url = "https://desktop.line-scdn.net/win/new/LineInst.exe";
    hash = "sha256-NQGOGJghiPxfSF9GLnp3+t5+DLYy+vYy4WNiKBW56Qo="; # :hash:
  };

  dontUnpack = true;
  wineArch = "win64";
  persistRegistry = false;
  persistRuntimeLayer = true;
  enableMonoBootPrompt = false;
  graphicsDriver = "auto"; # Note: Does not work with Wayland
  nativeBuildInputs = [
    copyDesktopItems
    copyDesktopIcons
  ];

  fileMap = {
    "$HOME/.local/share/line/Data" = "drive_c/users/$USER/AppData/Local/LINE/Data";
    "$HOME/.local/share/line-call/Data" = "drive_c/users/$USER/AppData/Local/LineCall/Data";
  };

  enabledWineSymlinks = {
    desktop = false;
  };

  winAppInstall = ''
    winetricks win10
    $WINE ${src} /S
    wineserver -w
    mkdir -p "$WINEPREFIX/drive_c/users/$USER/AppData/Local/LINE/Data"
  '';

  winAppRun = ''
    $WINE start /unix "$WINEPREFIX/drive_c/users/$USER/AppData/Local/LINE/bin/LineLauncher.exe"
  '';

  installPhase = ''
    runHook preInstall

    ln -s $out/bin/.launcher $out/bin/line

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = pname;
      exec = pname;
      icon = pname;
      desktopName = "LINE";
      categories = [
        "Network"
        "Chat"
      ];
    })
  ];

  desktopIcon = makeDesktopIcon {
    name = "line";

    src = fetchurl {
      url = "https://line.me/favicon-32x32.png";
      sha256 = "1kry4kab23d8knz1yggj3a0mdz56n7zf6g5hq4sbymdm103j4ksh";
    };
  };

  meta = with lib; {
    homepage = "https://line.me";
    description = "LINE is new level of communication, and the very infrastructure of your life.";
    license = licenses.unfree;
    maintainers = with maintainers; [ emmanuelrosa ];
    platforms = [ "x86_64-linux" ];
  };
}
