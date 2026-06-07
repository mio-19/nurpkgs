{
  antigravity-cli,
  python3,
}:

antigravity-cli.overrideAttrs (oldAttrs: {
  pname = "antigravity-cli-patched";

  nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ python3 ];

  postInstall = (oldAttrs.postInstall or "") + ''
    python3 -c '
    import os
    path = "'$out'/bin/agy"
    with open(path, "rb") as f:
        data = bytearray(f.read())

    # Patch 1: "\n  %s\n\n" -> "\n%s\n\n\n\n"
    pattern1 = b"\x0a  %s\x0a\x0a"
    new1 = b"\x0a%s\x0a\x0a\x0a\x0a"
    if pattern1 in data:
        data = data.replace(pattern1, new1)
        print("Patched pattern 1")

    # Patch 2: "  %s  " -> "%s    "
    pattern2 = b"  %s  "
    new2 = b"%s    "
    if pattern2 in data:
        data = data.replace(pattern2, new2)
        print("Patched pattern 2")

    with open(path, "wb") as f:
        f.write(data)
    '
  '';
})
