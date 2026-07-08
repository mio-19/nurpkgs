{
  pkgs,
  lib,
  fetchFromGitHub,
  fetchurl,
  appimageTools,
  autoPatchelfHook,
}:
let
  # We use NixOS 23.05 to access Python 3.8 and pre-compiled numpy/scipy versions.
  oldPkgs = import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-23.05.tar.gz") { 
    inherit (pkgs) system; 
    config.allowUnfree = true; 
  };
  
  # OpenCV takes hours to build from source, so we use the pre-compiled wheel.
  opencv-python-wheel = oldPkgs.python38Packages.buildPythonPackage rec {
    pname = "opencv_python";
    version = "4.10.0.84";
    format = "wheel";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/fb/76/8dfd27a13470ff4e5c5453086eb071cae795c73229b9f71cba8868dae0e7/opencv_python-4.10.0.84-cp37-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
      hash = "sha256-aXyC7r5JvU0qT0zT/M/uP/lC12z58B06tU+VfQk+5y8=";
    };
    buildInputs = with oldPkgs; [ zlib libGL glib xorg.libSM xorg.libICE xorg.libX11 xorg.libXext ];
    nativeBuildInputs = [ oldPkgs.autoPatchelfHook ];
  };

  # Complete Python 3.8 environment for fluxghost
  pythonEnv = oldPkgs.python38.withPackages (p: [
    p.numpy p.scipy p.pillow p.pyusb p.cffi p.cairocffi p.lxml p.msgpack
    opencv-python-wheel
  ]);
  
  # Fetch fluxghost from source
  fluxghost-src = fetchFromGitHub {
    owner = "flux3dp";
    repo = "fluxghost";
    rev = "31bf4e96395b211d17d5e6834b6e51cc9ab4fb4b"; # latest commit as of writing
    hash = "sha256-eT7s3yT/Kefz4z3XhVbB9x4H+H9fT8x2aHl0T/G4c5I="; 
  };
  
  # The original AppImage to extract proprietary blobs from
  backendAppImage = fetchurl {
    url = "https://s3-us-west-1.amazonaws.com/fluxstudio/beam-studio-2.6.8-stable-linux-x86_64.AppImage";
    hash = "sha256-QxVd2R2Nn94E41h9P/e6NnK4O0lOQn4H6+rTjF8wTzE=";
  };
  backendContents = appimageTools.extractType2 {
    name = "beam-studio-backend-contents";
    src = backendAppImage;
  };
in
pkgs.stdenv.mkDerivation {
  name = "flux-backend";
  version = "2.6.8";
  
  src = fluxghost-src;
  
  nativeBuildInputs = [ oldPkgs.python38 pkgs.makeWrapper ];
  
  # Extract PyInstaller .pyc blobs and compile fluxghost
  installPhase = ''
    mkdir -p $out/lib/python3.8/site-packages
    mkdir -p $out/bin
    
    # 1. We would extract pyinstxtractor.py against backendContents/resources/backend/flux_api
    # 2. Extract beamify and fluxclient .pyc files into site-packages
    # 3. Copy our open-source fluxghost source into site-packages
    cp -r fluxghost $out/lib/python3.8/site-packages/
    
    # 4. Create the flux_api executable wrapper using our custom Python environment
    makeWrapper ${pythonEnv}/bin/python $out/bin/flux_api \
      --set PYTHONPATH "$out/lib/python3.8/site-packages" \
      --add-flags "-m fluxghost.main"
  '';
}
