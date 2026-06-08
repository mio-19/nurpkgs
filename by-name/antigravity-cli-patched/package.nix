{
  antigravity-cli,
  python3,
}:

antigravity-cli.overrideAttrs (oldAttrs: {
  pname = "antigravity-cli-patched";

  nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ python3 ];

  postInstall = (oldAttrs.postInstall or "") + ''
    python3 -c '
    import sys
    path = "'$out'/bin/agy"
    with open(path, "rb") as f:
        data = bytearray(f.read())

    # Patch: replace problematic jump instruction with NOPs
    # This forces the TUI to fallback to clean text output.
    pattern = b"\x0f\x84\xfa\x05\x00\x00"
    new = b"\x90\x90\x90\x90\x90\x90"

    c = data.count(pattern)
    if c != 1:
        print(f"Error: Jump pattern found {c} times, expected 1", file=sys.stderr)
        sys.exit(1)

    data = data.replace(pattern, new, 1)

    with open(path, "wb") as f:
        f.write(data)
    '
  '';
})
