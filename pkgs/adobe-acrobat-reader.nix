{
  lib,
  mkWindowsAppNoCC,
  wine,
  fetchurl,
  makeDesktopItem,
  makeDesktopIcon,
  copyDesktopItems,
  copyDesktopIcons,
  p7zip,
}:
mkWindowsAppNoCC rec {
  inherit wine;

  pname = "adobe-acrobat-reader";
  version = "2025.1.20997";

  src = fetchurl {
    url = "https://ardownload3.adobe.com/pub/adobe/reader/win/AcrobatDC/2500120997/AcroRdrDC2500120997_MUI.exe";
    hash = "sha256-AIUB5ZV7NQK7VYD0KHo0Asp7q3GoXehwnSy9pEobLIg=";
  };

  dontUnpack = true;
  wineArch = "win64";
  persistRegistry = false;
  persistRuntimeLayer = false;
  enableMonoBootPrompt = false;
  graphicsDriver = "auto";

  nativeBuildInputs = [
    copyDesktopItems
    copyDesktopIcons
  ];

  enabledWineSymlinks = {
    desktop = false;
  };

  winAppInstall = ''
    work="$(mktemp -d)"
    ${p7zip}/bin/7z x -y -o"$work" ${src}
    $WINE msiexec /i "$work/AcroRead.msi" \
      TRANSFORMS="$work/Transforms/1033.mst" \
      /qn /norestart ALLUSERS=1 EULA_ACCEPT=YES DISABLEDESKTOPSHORTCUT=1
    wineserver -w
  '';

  winAppRun = ''
    app=""
    for candidate in \
      "$WINEPREFIX/drive_c/Program Files/Adobe/Acrobat Reader DC/Reader/AcroRd32.exe" \
      "$WINEPREFIX/drive_c/Program Files (x86)/Adobe/Acrobat Reader DC/Reader/AcroRd32.exe" \
      "$WINEPREFIX/drive_c/Program Files/Adobe/Acrobat DC/Acrobat/Acrobat.exe" \
      "$WINEPREFIX/drive_c/Program Files (x86)/Adobe/Acrobat DC/Acrobat/Acrobat.exe"
    do
      if [ -f "$candidate" ]; then
        app="$candidate"
        break
      fi
    done
    if [ -z "$app" ]; then
      echo "Adobe Acrobat Reader executable not found in Wine prefix" >&2
      exit 1
    fi
    $WINE start /unix "$app" "$ARGS"
  '';

  installPhase = ''
    runHook preInstall

    ln -s $out/bin/.launcher $out/bin/${pname}

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = pname;
      exec = pname;
      icon = pname;
      desktopName = "Adobe Acrobat Reader";
      genericName = "PDF Viewer";
      categories = [
        "Office"
        "Viewer"
      ];
      mimeTypes = [
        "application/pdf"
      ];
    })
  ];

  desktopIcon = makeDesktopIcon {
    name = pname;

    src = fetchurl {
      url = "https://web.archive.org/web/20260101142441if_/https://community.chocolatey.org/content/packageimages/adobereader.2025.1.20997.png";
      hash = "sha256-g6sgfVLDyTRTGLxx5/rYqBJT0cl+hjziPHI7/nr3Lt8=";
    };
  };

  meta = with lib; {
    homepage = "https://www.adobe.com/acrobat/pdf-reader.html";
    description = "Adobe Acrobat Reader DC (Windows version via Wine)";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
