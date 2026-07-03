#!/bin/bash

echo "=== Updating system packages (dnf) ==="
sudo dnf upgrade --refresh

echo "=== Updating Python LSP (pip) ==="
pip install --upgrade pyright

echo "=== Updating JS/TS LSP (npm) ==="
npm update -g typescript typescript-language-server

echo "=== Done ==="
echo "Remember to update Emacs packages with M-x package-list-packages and then hit 'U'"
