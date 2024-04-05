#!/usr/bin/env sh
set -e
set -x
nix build .#tools && nix path-info -r .#tools | tar czf tools.tar.gz -P -T -
