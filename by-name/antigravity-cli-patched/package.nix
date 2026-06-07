{
  antigravity-cli,
  python3,
}:

antigravity-cli.overrideAttrs (oldAttrs: {
  pname = "antigravity-cli-patched";

  nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ python3 ];

  postInstall = (oldAttrs.postInstall or "") + ''
    python3 -c '
    import os, sys
    path = "'$out'/bin/agy"
    with open(path, "rb") as f:
        data = bytearray(f.read())

    # Patch 1: "\n  %s\n\n" -> "\n%s\n\n\n\n"
    # Removes leading spaces from the "visit the URL to log in" block
    pattern1 = b"\x0a  %s\x0a\x0a"
    new1 = b"\x0a%s\x0a\x0a\x0a\x0a"
    c1 = data.count(pattern1)
    if c1 != 1:
        print(f"Error: Pattern 1 found {c1} times, expected 1", file=sys.stderr)
        sys.exit(1)
    data = data.replace(pattern1, new1, 1)

    # Patch 2: "  %s  " -> "%s    "
    # Removes spaces around the URL in the "click on the link below" block
    pattern2 = b"  %s  "
    new2 = b"%s    "
    c2 = data.count(pattern2)
    if c2 != 1:
        print(f"Error: Pattern 2 found {c2} times, expected 1", file=sys.stderr)
        sys.exit(1)
    data = data.replace(pattern2, new2, 1)

    with open(path, "wb") as f:
        f.write(data)
    '
  '';

})
