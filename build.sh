#!/usr/bin/env sh
set -e
output=$(nix build --no-link --print-out-paths .#runScript)
cp $output ./run
chmod u+w ./run
#buildOutput=$(nix build .#toolsBundle --print-out-paths --no-link)
#for file in "$buildOutput"/*; do
#  base=$(basename "${file}")
#  cp "${file}" "./${base}"
#  chmod u+w "${base}"
#done
