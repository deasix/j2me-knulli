#!/bin/bash
# 
# package res, jdk, and patch file into a single executable

# logging
set -euo pipefail
F_LOG="/tmp/j2me-knulli-build.log"
exec > >(tee -a "$F_LOG") 2> >(tee -a "$F_LOG" >&2)
trap 'echo "Error occurred. See logs: $F_LOG"; exit 1' ERR

# system
D_TMP=$(mktemp -d)

# optional parameters
BUILD="${1:-"build"}"
OUPUT="${2:-"j2me-knulli.sh"}"

# resources
F_JDK="jdk.tar.gz"
F_RES="res.tar.gz"

# create directories
mkdir -pv "$BUILD"

# repackage minimal jdk
echo "Building jdk..."
./jdk.sh "$D_TMP/$F_JDK" "$BUILD/$F_JDK"

# embed res & jdk to patch
echo "Building patch..."
tar -czf "$D_TMP/$F_RES" -C "res" $(ls res) -C "$D_TMP" "$F_JDK"
cp "patch.sh" "$D_TMP/$OUPUT"
cat "$D_TMP/$F_RES" >> "$D_TMP/$OUPUT"
mv "$D_TMP/$OUPUT" "$BUILD/"

# cleanup
echo "Cleaning up..."
rm -r "$D_TMP"
rm "$F_LOG"

# exit
echo "Done."
exit 0
