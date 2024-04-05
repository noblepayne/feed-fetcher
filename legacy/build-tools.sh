#!/usr/bin/env sh
set -e
set -x
nix build .#archiver && nix path-info -r .#archiver| tar czf tools.tar.gz -P -T -
