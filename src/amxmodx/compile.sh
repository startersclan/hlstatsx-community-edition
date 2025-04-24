#!/bin/sh 
set -eu

VER=${VER:-1.8.2}
SCRIPT_DIR=$( cd "$( dirname "$0" )" && pwd )

if [ ! -f "$SCRIPT_DIR"/scripting/amxxpc ]; then 
    echo "Installing compiler..."
    cd "$SCRIPT_DIR"
    curl -O https://www.amxmodx.org/release/amxmodx-"$VER"-base-linux.tar.gz
    tar --strip-components=2 -zxvf amxmodx-"$VER"-base-linux.tar.gz -- addons/amxmodx/scripting/include addons/amxmodx/scripting/amxxpc addons/amxmodx/scripting/amxxpc32.so
    rm -fv amxmodx-"$VER"-base-linux.tar.gz
fi

echo
echo "Compiling..."
cd "$SCRIPT_DIR/scripting"
for i in *.sma; do 
    ./amxxpc "$i" -o"../plugins/$( basename "$i" .sma).amxx"
    realpath "../plugins/$( basename "$i" .sma).amxx"
done
