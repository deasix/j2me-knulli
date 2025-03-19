#!/bin/bash
# 
# package res, jdk, and patch file into a single executable

# capture logs
set -euo pipefail
log="/tmp/j2me-knulli-build.log"
exec > >(tee -a "$log") 2> >(tee -a "$log" >&2)
trap 'echo "Error occurred. See logs: $log"; exit 1' ERR

# system
tmp="$(mktemp -d)"

# optional parameters
build="${1:-"build"}"
output="${2:-"j2me-knulli.sh"}"

# resources
f_jdk="jdk.tar.gz"
f_res="res.tar.gz"

# create directories
mkdir -pv "$build"

# repackage minimal jdk
echo "Building jdk..."
./jdk.sh "$tmp/$f_jdk" "$build/$f_jdk"

# embed res & jdk to patch
echo "Building patch..."
tar -czf "$tmp/$f_res" -C "res" $(ls res) -C "$tmp" "$f_jdk"
cp "patch.sh" "$tmp/$output"
cat "$tmp/$f_res" >> "$tmp/$output"
mv "$tmp/$output" "$build/"

# cleanup
echo "Cleaning up..."
rm -r "$tmp"
rm "$log"

# exit
echo "Done."
exit 0
