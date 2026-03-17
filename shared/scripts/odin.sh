#!/usr/bin/env bash

set -e

URL=$(curl -s https://api.github.com/repos/odin-lang/Odin/releases |
  grep browser_download_url |
  grep linux-amd64 |
  head -n 1 |
  cut -d '"' -f 4)

FILE=$(basename "$URL")
curl -LO "$URL"

mkdir -p "$HOME/.local/bin"
tar -C "$HOME/.local/bin" -xzf "$FILE"

EXTRACTED_DIR=$(tar -tzf "$FILE" | head -1 | cut -f1 -d"/")
mv "$HOME/.local/bin/$EXTRACTED_DIR" "$HOME/.local/bin/odin"

rm "$FILE"
