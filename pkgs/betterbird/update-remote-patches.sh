#!/usr/bin/env bash
set -euo pipefail

cd -- "$(readlink -f -- "$(dirname -- "$0")")"

td="$(mktemp -d)"
trap 'rm -rf -- "$td"' EXIT

nix build .#betterbird-unwrapped.betterbird-patches-plain --out-link "$td/betterbird-patches"

declare -a series_lines=()
mapfile -t series_lines < <(cat "$td/betterbird-patches/140/"{series,series-moz})

trim() {
    local var="$1"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

printf '' > patchdata.jsonl #truncate

for line in "${series_lines[@]}"; do
  line="${line%%##*}" # remove everything after ##
  line="$(trim "$line")"
  if [[ $line != *' # '* ]]; then
    continue
  fi
  patchname="${line%%#*}"
  patchname="$(trim "$patchname")"
  url="${line##*#}"
  url="$(trim "$url")"
  url="${url/\/rev\//\/raw-rev\/}"
  # declare -p patchname url
  declare the_hash
  the_hash="$(nix store prefetch-file --json --name "$patchname" -- "$url" | jq -r '.hash')"
  echo "$patchname: $the_hash";
  printf '{"url": "%q", "name": "%q", "hash": "%q"}\n' "$url" "$patchname" "$the_hash" >> patchdata.jsonl
done

jq -s '.' < patchdata.jsonl > patchdata.json
rm patchdata.jsonl
