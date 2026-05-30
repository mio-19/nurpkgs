{
  lib,
  fetchurl,
  cid,
  datalog,
  ocaml-index,
  ocamlPackages,
}:

ocamlPackages.buildDunePackage rec {
  pname = "forester";
  version = "83197f3d0c42de4aa01d4c2522f6399a5070320c";

  src = fetchurl {
    url = "https://git.sr.ht/~jonsterling/ocaml-forester/archive/${version}.tar.gz";
    hash = "sha256-M5bQt0DEf+xszxJ6YFCOiY/BnATSKTqov5qvA4m0Cw8=";
  };

  strictDeps = true;

  patches = [
    ./cmdliner-env-shadow.patch
  ];

  nativeBuildInputs = with ocamlPackages; [
    js_of_ocaml-compiler
    menhir
  ];

  propagatedBuildInputs = with ocamlPackages; [
    alcotest
    algaeff
    asai
    base64
    bisect_ppx
    bwd
    brr
    cid
    cmdliner
    cohttp-eio
    datalog
    dune-build-info
    dune-site
    eio_main
    jsonrpc
    logs
    lsp
    ocaml-index
    ocamlgraph
    ppx_deriving
    ppx_repr
    ppx_yojson_conv
    ptime
    pure-html
    repr
    routes
    spelll
    toml
    uri
    uucp
    yojson
    yuujinchou
  ];

  meta = {
    description = "Tool for tending mathematical forests";
    homepage = "https://sr.ht/~jonsterling/forester/";
    changelog = "https://git.sr.ht/~jonsterling/ocaml-forester/log/${version}";
    license = lib.licenses.gpl3Plus;
    maintainers = [ ];
    mainProgram = "forester";
  };
}
