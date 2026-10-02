import re
import os
import subprocess
import json

updates_text = """
    [UPDATE] socketw (RigsOfRods/SocketW on github.com): 35cd91e -> 813375e
    [UPDATE] android-translation-layer (android_translation_layer/android_translation_layer on gitlab.com): b4bd403 -> aa80e74
    [UPDATE] bilibili (msojocs/bilibili-linux on github.com): v1.19.0-1 -> v1.19.0-3
    [UPDATE] bionic-translation (android_translation_layer/bionic_translation on gitlab.com): fb9d2ec -> 6253dec
    [UPDATE] bitwarden-extension (bitwarden/clients on github.com): browser-v2026.9.2 -> browser-v2026.9.3
    [UPDATE] clice (clice-io/clice on github.com): v0.1.2026092407 -> v0.1.2026100108
    [UPDATE] floccus-firefox (floccusaddon/floccus on github.com): v5.10.3 -> v5.11.0
    [UPDATE] forkgram-desktop (forkgram/tdesktop on github.com): v7.2.9 -> v7.2.10
    [UPDATE] meru (zoidsh/meru on github.com): v3.61.0 -> v3.62.0
    [UPDATE] mesh-llm (Mesh-LLM/mesh-llm on github.com): v0.76.2 -> v0.77.0
    [UPDATE] nlvm (fetchgit https://github.com/arnetheduck/nlvm.git): b099f25 -> 40d7339
    [UPDATE] terminal-browser (zenbu-labs/terminal-browser on github.com): v0.11.1 -> v0.13.3
    [UPDATE] unsloth-studio (unslothai/unsloth on github.com): v0.1.815-beta -> v0.1.902-beta
    [UPDATE] user-agent-switcher-firefox (ntninja/user-agent-switcher on gitlab.com): v1.4.106 -> v1.4.107
"""

updates = []
for line in updates_text.strip().split('\n'):
    m = re.match(r'\s*\[UPDATE\] ([\w-]+) .*?: (.*?) -> (.*)', line)
    if m:
        updates.append({
            'pkg': m.group(1),
            'old': m.group(2).strip(),
            'new': m.group(3).strip()
        })

for u in updates:
    pkg = u['pkg']
    # find file
    paths = [
        f"pkgs/{pkg}/package.nix",
        f"by-name/{pkg[:2]}/{pkg}/package.nix"
    ]
    path = None
    for p in paths:
        if os.path.exists(p):
            path = p
            break
    if not path:
        print(f"Could not find path for {pkg}")
        continue
    
    with open(path, 'r') as f:
        content = f.read()

    # Special handling for rev vs version
    if 'fetchFromGitHub' in content or 'fetchgit' in content or 'fetchFromGitLab' in content:
        # replace version if old version is in there
        # old is often a short commit hash. Let's see if we can use nix-update.
        print(f"Running nix-update for {pkg} to {u['new']}")
        res = subprocess.run(["nix-update", "-f", "default.nix", pkg, "--version", u['new']], capture_output=True, text=True)
        if res.returncode != 0:
            print(f"nix-update failed for {pkg}:\n{res.stderr}")
            # If it failed, let's manually modify package.nix
            pass
        else:
            print(f"nix-update success for {pkg}")
