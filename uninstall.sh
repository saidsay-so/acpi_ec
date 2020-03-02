#!/bin/bash
# This script was partly inspired by https://github.com/atar-axis/xpadneo/blob/master/uninstall.sh

if [[ "$EUID" != 0 ]]; then
    echo "The script need to be run as root."
    exit 1
fi

MODULE_NAME=acpi_ec
SIGN_DIR=/root/module-signing/

modprobe -r $MODULE_NAME

VERSIONS=($(dkms status 2>/dev/null | sed -E -n "s/$MODULE_NAME, ([0-9]+.[0-9]+.[0-9]+).*/\1/ p" | sort -u))
for version in "${VERSIONS[@]}"; do
    dkms remove -m $MODULE_NAME -v "$version" --all
    rm -rf "/usr/src/$MODULE_NAME-$version/"
done

if [[ -f "$SIGN_DIR/MOK.der" ]]; then
    echo -n "Do you want to remove the generated key? (y/N) "
    read -r RES
    echo

    case $RES in
    [yY]*)
        mokutil --delete "$SIGN_DIR/MOK.der" 2>/dev/null
        rm -rf "$SIGN_DIR"
        echo "Successfully deleted and revoked the key."
        ;;

    *) ;;
    esac
fi
