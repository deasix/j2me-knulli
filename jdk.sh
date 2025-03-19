#!/bin/bash
#
# create a minimal jdk from local file or download from www.azul.com
# define jdk url and version should you opt to use other version
#
# see: https://cdn.azul.com/zulu-embedded/bin/
# see: https://www.azul.com/downloads/?package=jdk#zulu 

# capture logs
set -euo pipefail
log="/tmp/j2me-knulli-jdk.log"
exec > >(tee -a "$log") 2> >(tee -a "$log" >&2)
trap 'echo "Error occurred. See logs: $log"; exit 1' ERR

# system
tmp="$(mktemp -d)"

# optional parameters
output="${1:-"min-jdk.tar.gz"}"
input="${2:-"jdk.tar.gz"}"

# strings
jdk_ver="zulu11.48.21-ca-jdk11.0.11-linux_aarch64.tar.gz"
jdk_url="https://cdn.azul.com/zulu-embedded/bin/$jdk_ver"

# find or download jdk 
echo "Searching jdk file..."
if [ ! -f "$input" ]; then
   echo "Attempting to download..."
   
   if ! ping -c 1 -W 1 8.8.8.8 > /dev/null 2>&1; then
      echo "No internet connection."
      echo "Place jdk at $(readlink -f "$input")."
      exit 1 # consider cleanup
   fi
   
   echo "Downloading jdk..." 
   wget -O "$input" "$jdk_url"
fi

# repackage minimal jdk
echo "Trimming jdk..."
tar -xzf "$input" -C "$tmp" --strip-components 1;
tar -czf "$output" -C "$tmp" lib bin conf

# cleanup
echo "Cleaning up..."
rm -rf "$tmp"
rm "$log"

# exit
echo "Done."
exit 0
