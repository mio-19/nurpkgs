{
  lib,
  applyPatches,
  fetchFromGitHub,
  fetchurl,
  haskell,
  haskellPackages,
  wrapGAppsHook3,
  gsettings-desktop-schemas,
  gtk3,
  gdk-pixbuf,
  gst_all_1,
  ffmpeg,
  imagemagick,
}:

let
  version = "6.0.1.0";
  src = applyPatches {
    src = fetchFromGitHub {
      owner = "lettier";
      repo = "gifcurry";
      rev = "refs/tags/${version}";
      hash = "sha256-3xYGWIXLXxsjTgpEGObYG7z+WGFL2W+vUkGcBaGEEUE=";
    };
    patches = [
      (fetchurl {
        url = "https://github.com/nicholasmullikin/gifcurry/commit/621326558911f21cdb6fee6c787c17845d2d3a89.patch";
        hash = "sha256-NkaSEwSKcBKPoWGmsVUIKJS3RPDKpk0X7z7iaHo8RLE=";
      })
      ./gifcurry-gtk3-deps.patch
      ./gifcurry-data-text-qualify.patch
      ./gifcurry-gui-misc-text-qualify.patch
      ./gifcurry-gui-main-text-qualify.patch
      ./gifcurry-use-magick.patch
    ];
  };

  base = haskellPackages.callCabal2nix "gifcurry" src { };
in
haskell.lib.doJailbreak (
  base.overrideAttrs (old: {
    inherit src version;

    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ wrapGAppsHook3 ];
    buildInputs = (old.buildInputs or [ ]) ++ [
      gtk3
      gdk-pixbuf
      gsettings-desktop-schemas
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-libav
    ];

    gappsWrapperArgs = (old.gappsWrapperArgs or [ ]) ++ [
      "--prefix"
      "PATH"
      ":"
    "${lib.makeBinPath [
        ffmpeg
        imagemagick
        gst_all_1.gstreamer
      ]}"
    ];

    postInstall = (old.postInstall or "") + ''
      install -Dm644 packaging/linux/common/com.lettier.gifcurry.desktop \
        $out/share/applications/com.lettier.gifcurry.desktop
      install -Dm644 packaging/linux/common/com.lettier.gifcurry.svg \
        $out/share/icons/hicolor/scalable/apps/com.lettier.gifcurry.svg
      install -Dm644 packaging/linux/common/com.lettier.gifcurry.appdata.xml \
        $out/share/metainfo/com.lettier.gifcurry.appdata.xml
    '';

    meta = with lib; {
      description = "Haskell-built video editor for GIF makers (GUI and CLI)";
      homepage = "https://github.com/lettier/gifcurry";
      license = licenses.bsd3;
      mainProgram = "gifcurry_gui";
      platforms = platforms.linux;
    };
  })
)
