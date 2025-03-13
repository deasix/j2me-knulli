#!/bin/bash
#
# add j2me support to knulli
# core & bios directly pulled from rocknix
# documentation references from knulli & batocera
# credit goes to respective teams & owners :)
#
# see: https://knulli.org/configure/patches-and-overlays/
# see: https://wiki.batocera.org/emulationstation:customize_systems
# see: https://wiki.batocera.org/systems:ports#installing_the_java_runtime_environment

# logging
set -euo pipefail
F_LOG="/tmp/j2me-knulli.log"
exec > >(tee -a "$F_LOG") 2> >(tee -a "$F_LOG" >&2)
trap 'echo "Error occurred. See logs: $F_LOG"; exit 1' ERR

# config | 'false' on test!
DELETE="true" 
REBOOT="true"
SAVE="true"
SIZE="256"

# system
R="${1:-""}"
D_TMP="$(mktemp -d)"
D_SYS_JAVA="$R/opt/java"
D_SYS_JBIN="$R/usr/bin/java"
D_SYS_CORE="$R/usr/lib/libretro"
D_SYS_ESDE="$R/usr/share/emulationstation"

# batocera
D_SYS_BIOS="$R/usr/share/batocera/datainit/bios"
D_SYS_J2ME="$R/usr/share/batocera/datainit/roms/j2me"

# userdata
D_USR_BIOS="$R/userdata/bios"
D_USR_J2ME="$R/userdata/roms/j2me"

# configs
F_SYS_CFGG="$R/usr/share/batocera/configgen/configgen-defaults.yml"
F_SYS_ESFT="$R/usr/share/emulationstation/es_features.cfg"

# patch files
F_RES_JSYS="es_systems_j2me.cfg"
F_RES_CORE="freej2me_libretro.so"
F_RES_BIOS="freej2me-lr.jar"
F_RES_JAVA="jdk.tar.gz"
F_RES_JINF="_info.txt"

# create directories
echo "Creating directories..."
mkdir -pv "$D_SYS_JAVA" "$D_SYS_J2ME" "$D_USR_J2ME"

# unpack embedded resources
echo "Unpacking patch files..."
sed -n '/^# TARBALL_DATA/,$p' "$0" | tail -n +2 | tar -xvzm -C "$D_TMP"

# copy freej2me resources
echo "Adding freej2me..."
cp -v "$D_TMP/$F_RES_CORE" "$D_SYS_CORE/" # core
cp -v "$D_TMP/$F_RES_BIOS" "$D_SYS_BIOS/" # system bios
cp -v "$D_TMP/$F_RES_BIOS" "$D_USR_BIOS/" # userdata bios
chmod 755 "$D_SYS_CORE/$F_RES_CORE"

# copy j2me resources
echo "Adding j2me resources..."
cp -v "$D_TMP/$F_RES_JINF" "$D_SYS_J2ME/" # system roms
cp -v "$D_TMP/$F_RES_JINF" "$D_USR_J2ME/" # userdata roms
cp -v "$D_TMP/$F_RES_JSYS" "$D_SYS_ESDE/" # emuatiostation

# write to es_features.cfg | spacing is intended
echo "Updating es-features.cfg..."
if ! grep -q "freej2me" "$F_SYS_ESFT"; then
   sed -i '/<emulator name="libretro" features="">/,/<\/cores>/ { 
   /<cores>/a\
      <core name="freej2me" features="netplay, rewind, autosave" />
   }' "$F_SYS_ESFT"
fi
# --- end

# write to configgen-defaults.yml | spacing is intended
echo "Updating configgen-defaults.yml..."
if ! grep -q "freej2me" "$F_SYS_CFGG"; then
cat <<EOF >> "$F_SYS_CFGG"

# j2me-knulli.sh

j2me:
  emulator: libretro
  core:     freej2me
EOF
fi
# --- end

# java
echo "Installing java..."
tar -xvzmf "$D_TMP/$F_RES_JAVA" -C "$D_SYS_JAVA"
ln -fnsv "$D_SYS_JAVA/bin/java" "$D_SYS_JBIN"
   
# cleanup
echo "Cleaning up..."
rm -rfv "$D_TMP"

# self delete
if [[ "${DELETE:-false}" == "true" ]]; then
   echo "Deleting script..."
   rm -v -- "$0" &
fi

# persist
if [[ "${SAVE:-false}" == "true" ]]; then
   echo "Persisting changes..."
   batocera-save-overlay $SIZE
fi

# reboot
if [[ "${REBOOT:-false}" == "true" ]]; then
   echo "Rebooting system..."
   sleep 1 && reboot
fi

# exit | may not reach after `reboot`
echo "Done. See logs at $F_LOG."
exit 0

# TARBALL_DATA
