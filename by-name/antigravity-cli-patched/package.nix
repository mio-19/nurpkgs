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
    # Use a unique sequence including the next instruction to ensure only one match.
    pattern = b"\x0f\x84\xfa\x05\x00\x00\x4c\x89\x94\x24\xe0\xb8\x00\x00"
    new = b"\x90\x90\x90\x90\x90\x90\x4c\x89\x94\x24\xe0\xb8\x00\x00"

    c = data.count(pattern)
    if c != 1:
        print(f"Error: Unique pattern found {c} times, expected 1", file=sys.stderr)
        sys.exit(1)

    data = data.replace(pattern, new, 1)

    with open(path, "wb") as f:
        f.write(data)
    '
  '';
})
