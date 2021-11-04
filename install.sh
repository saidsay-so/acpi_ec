#!/bin/bash
# This script was partly inspired by https://github.com/atar-axis/xpadneo/blob/master/install.sh

source _variables.sh

set -e

if [[ "$EUID" != 0 ]]; then
  echo "The script need to be run as root."
  exit 1
fi

TEMP=$(mktemp -d)

generate_keys() {
  install -Dm700 -t "$SIGN_DIR" scripts/keys-setup.sh
  $SIGN_DIR/keys-setup.sh
}

ask_paths() {
  (read -erp "Enter the path of the public key: " PUB_KEY && [[ -f "$PUB_KEY" ]]) || return 1
  (read -erp "Enter the path of the private key: " PRIV_KEY && [[ -f "$PRIV_KEY" ]]) || return 1
}

cleanup() {
  rm -rf "$TEMP"
  exit 1
}
trap cleanup INT

if ! command -v dkms >/dev/null 2>&1; then
  echo "DKMS should be installed!"
  exit 1
fi

VERSION=$(git describe --tags --abbrev=0)
MOD_SRC_DIR="/usr/src/$MODULE_NAME-$VERSION"

if ! (dkms status 2>/dev/null | grep -q "$MODULE_NAME/${VERSION}.*installed"); then # if the module is already installed in DKMS

  # For Debian
  if command -v update-secureboot-policy >/dev/null 2>&1; then
    update-secureboot-policy --new-key
    update-secureboot-policy --enroll-key
  elif [[ $(mokutil --sb-state 2>/dev/null) == *"enabled"* ]]; then # if Secure boot is enabled
    if [[ $(mokutil --test-key "$SIGN_DIR/mok.der" 2>/dev/null) != *"already"* ]]; then # if our keys are not already generated/enrolled by the MOK
      generate_keys
    fi
  else
    echo "WARNING: Secure Boot is not enabled!"
  fi

  if [[ ! -d "$MOD_SRC_DIR" ]]; then
    mkdir -p "$MOD_SRC_DIR"
    cp -R "$PWD/src/" "$MOD_SRC_DIR/src"
  fi

  cp dkms.conf "$MOD_SRC_DIR/dkms.conf"
  sed -i "s/PACKAGE_VERSION=.*/PACKAGE_VERSION=\"$VERSION\"/" "$MOD_SRC_DIR/dkms.conf"
  dkms add -m "$MODULE_NAME" -v "$VERSION"
  dkms build -m "$MODULE_NAME" -v "$VERSION"
  dkms install -m "$MODULE_NAME" -v "$VERSION"

  # module auto-loading
  echo "acpi_ec" > /etc/modules-load.d/acpi_ec.conf

else
  echo "$MODULE_NAME ${VERSION} is already installed"
  exit 1
fi
