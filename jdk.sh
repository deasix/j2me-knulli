#!/bin/bash
#
# create a minimal jdk from local file or download from www.azul.com
# define jdk url and version should you opt to use other version
#
# see: https://cdn.azul.com/zulu-embedded/bin/
# see: https://www.azul.com/downloads/?package=jdk#zulu 

# logging
set -euo pipefail
F_LOG="/tmp/j2me-knulli-jdk.log)"
exec > >(tee -a "$F_LOG") 2> >(tee -a "$F_LOG" >&2)
trap 'echo "Error occurred. See logs: $F_LOG"; exit 1' ERR

# system
D_TMP="$(mktemp -d)"

# optional parameters
OUTPUT=${1:-"min-jdk.tar.gz"}
INPUT="${2:-"jdk.tar.gz"}"

# strings
JDK_VER="zulu11.48.21-ca-jdk11.0.11-linux_aarch64.tar.gz"
JDK_URL="https://cdn.azul.com/zulu-embedded/bin/${JDK_VER}"

# find or download jdk 
echo "Searching jdk file..."
if [ ! -f "$INPUT" ]; then
   echo "Attempting to download..."
   
   if ! ping -c 1 -W 1 8.8.8.8 > /dev/null 2>&1; then
      echo "No internet connection."
      echo "Place JDK at $(readlink -f $INPUT)."
      exit 1 # consider cleanup
   fi
   
   echo "Downloading jdk..." 
   wget -O "$INPUT" "$JDK_URL"
fi

# repackage minimal jdk
echo "Trimming jdk..."
tar -xzf "$INPUT" -C "$D_TMP" --strip-components 1;
tar -czf "$OUTPUT" -C "$D_TMP" lib bin conf

# cleanup
echo "Cleaning up..."
rm -rf "$D_TMP"
rm "$F_LOG"

# exit
echo "Done."
exit 0
