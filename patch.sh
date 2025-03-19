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

# capture logs
set -euo pipefail
log="/tmp/j2me-knulli.log"
exec > >(tee -a "$log") 2> >(tee -a "$log" >&2)
trap 'echo "Error occurred. See logs: $log"; exit 1' ERR

# config | 'false' on test!
delete="true" 
reboot="true"
save="true"
size="256"

# system
r="${1:-""}"
tmp="$(mktemp -d)"
d_sys_java="$r/opt/java"
d_sys_jbin="$r/usr/bin/java"
d_sys_core="$r/usr/lib/libretro"
d_sys_esde="$r/usr/share/emulationstation"

# batocera
d_sys_bios="$r/usr/share/batocera/datainit/bios"
d_sys_j2me="$r/usr/share/batocera/datainit/roms/j2me"

# userdata
d_usr_bios="$r/userdata/bios"
d_usr_j2me="$r/userdata/roms/j2me"

# configs
f_sys_cfgg="$r/usr/share/batocera/configgen/configgen-defaults.yml"
f_sys_esft="$r/usr/share/emulationstation/es_features.cfg"

# patch files
f_res_jsys="es_systems_j2me.cfg"
f_res_core="freej2me_libretro.so"
f_res_bios="freej2me-lr.jar"
f_res_java="jdk.tar.gz"
f_res_info="_info.txt"

# create directories
echo "Creating directories..."
mkdir -pv "$d_sys_java" "$d_sys_j2me" "$d_usr_j2me"

# unpack embedded resources
echo "Unpacking patch files..."
sed -n '/^# TARBALL_DATA/,$p' "$0" \
   | tail -n +2 | tar -xvzm -C "$tmp"

# copy freej2me resources
echo "Adding freej2me..."
cp -v "$tmp/$f_res_core" "$d_sys_core/" # core
cp -v "$tmp/$f_res_bios" "$d_sys_bios/" # system bios
cp -v "$tmp/$f_res_bios" "$d_usr_bios/" # userdata bios
chmod 755 "$d_sys_core/$f_res_core"

# copy j2me resources
echo "Adding j2me resources..."
cp -v "$tmp/$f_res_info" "$d_sys_j2me/" # system roms
cp -v "$tmp/$f_res_info" "$d_usr_j2me/" # userdata roms
cp -v "$tmp/$f_res_jsys" "$d_sys_esde/" # emuatiostation

# write to es_features.cfg | spacing is intended
echo "Updating es-features.cfg..."
if ! grep -q "freej2me" "$f_sys_esft"; then
   sed -i '/<emulator name="libretro" features="">/,/<\/cores>/ { 
   /<cores>/a\
      <core name="freej2me" features="netplay, rewind, autosave" />
   }' "$f_sys_esft"
fi
# --- end

# write to configgen-defaults.yml | spacing is intended
echo "Updating configgen-defaults.yml..."
if ! grep -q "freej2me" "$f_sys_cfgg"; then
cat <<EOF >> "$f_sys_cfgg"

# j2me-knulli.sh

j2me:
  emulator: libretro
  core:     freej2me
EOF
fi
# --- end

# java
echo "Installing java..."
tar -xvzmf "$tmp/$f_res_java" -C "$d_sys_java"
ln -fnsv "$d_sys_java/bin/java" "$d_sys_jbin"
   
# cleanup
echo "Cleaning up..."
rm -rfv "$tmp"

# self delete
if [[ "${delete:-false}" == "true" ]]; then
   echo "Deleting script..."
   rm -v -- "$0" &
fi

# persist
if [[ "${save:-false}" == "true" ]]; then
   echo "Persisting changes..."
   batocera-save-overlay "$size"
fi

# reboot
if [[ "${reboot:-false}" == "true" ]]; then
   echo "Rebooting system..."
   sleep 1 && reboot
fi

# exit | may not reach after `reboot`
echo "Done. See logs at $log."
exit 0

# TARBALL_DATA
