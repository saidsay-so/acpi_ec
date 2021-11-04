#!/bin/bash
# This script was partly inspired by https://github.com/atar-axis/xpadneo/blob/master/uninstall.sh

source _variables.sh

if [[ "$EUID" != 0 ]]; then
    echo "The script need to be run as root."
    exit 1
fi

modprobe -rq $MODULE_NAME

# Remove the module auto-loading
rm -f /etc/modules-load.d/acpi_ec.conf

mapfile -t VERSIONS < <(dkms status 2>/dev/null | sed -E -n "s#$MODULE_NAME.*(v[0-9]+.[0-9]+.[0-9]+).*#\1# p" | sort -u)

# FIX: v1.0.1 did not have a 'v' behind the version
if $(dkms status | grep -q "$MODULE_NAME.*1.0.1"); then
  VERSIONS+=( "1.0.1" )
fi

for version in "${VERSIONS[@]}"; do
    dkms uninstall "$MODULE_NAME/$version" --all
    dkms remove "$MODULE_NAME/$version" --all
    rm -rf "/usr/src/$MODULE_NAME-$version/"
    echo "Uninstalled $MODULE_NAME $version"
done

if [[ -f "$SIGN_DIR/mok.der" ]]; then
    echo -n "Do you want to remove the generated key? (y/N) "
    read -r RES
    echo

    case $RES in
    [yY]*)
        mokutil --delete "$SIGN_DIR/mok.der" 2>/dev/null
        rm -rf "$SIGN_DIR"
        echo "Successfully deleted and revoked the key."
        ;;

    *) ;;
    esac
fi

# Fix wrong folder issue
if [[ -f /root/mok.der ]]; then
    echo -n "Do you want to remove the generated key? (y/N) "
    read -r RES
    echo

    case $RES in
    [yY]*)
        mokutil --delete "/root/mok.der" 2>/dev/null
        rm -f /root/mok.der /root/mok.priv /root/keys-setup.sh
        echo "Successfully deleted and revoked the key."
        ;;

    *) ;;
    esac
fi
