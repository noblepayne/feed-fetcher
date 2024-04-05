#!/usr/bin/env sh
sudo tar xf ./tools.tar.gz -P
echo "$(find /nix -type d -iwholename '*/bin' | tr '\n' ':')$PATH"
