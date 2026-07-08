with import <nixpkgs> { };
appimageTools.extract {
  pname = "beam-studio";
  version = "2.6.8";
  src = fetchurl {
    url = "https://github.com/flux3dp/beam-studio/releases/download/v2.6.8/Beam.Studio-2.6.8.AppImage";
    hash = "sha256-R4F1eZ947Yy5DndqFzQW/cW3V7p/G65L1K4e7WfH4g4=";
  };
}
