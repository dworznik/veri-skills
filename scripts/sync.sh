#!/usr/bin/env bash
# Copies the veri plugin from veri.how into this repo. veri.how is the source:
# its /marketplace.json pins /plugins/veri.zip by sha256, and this repo carries
# the same files under plugins/veri/ with a relative source, because the Claude
# app adds a marketplace only from a repository.
set -euo pipefail

site=${VERI_SITE:-https://veri.how}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

curl -fsSL "$site/marketplace.json" -o "$work/marketplace.json"
url=$(jq -r '.plugins[] | select(.name == "veri") | .source.url' "$work/marketplace.json")
want=$(jq -r '.plugins[] | select(.name == "veri") | .source.sha256' "$work/marketplace.json")
curl -fsSL "$url" -o "$work/veri.zip"
have=$(sha256sum "$work/veri.zip" | cut -d' ' -f1)
if [ "$have" != "$want" ]; then
  echo "veri.zip sha256 $have does not match the pin $want" >&2
  exit 1
fi

rm -rf plugins/veri
mkdir -p plugins/veri .claude-plugin
unzip -q "$work/veri.zip" -d plugins/veri
jq '(.plugins[] | select(.name == "veri") | .source) = "./plugins/veri"' \
  "$work/marketplace.json" > .claude-plugin/marketplace.json
