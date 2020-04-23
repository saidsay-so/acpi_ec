#!/bin/bash
# This script was partly inspired by https://github.com/atar-axis/xpadneo/blob/master/install.sh

if [[ "$EUID" != 0 ]]; then
  echo "The script need to be run as root."
  exit 1
fi

MODULE_NAME=acpi_ec
VERSION=$(cat VERSION)
SIGN_DIR=/root/module-signing/
MOD_SRC_DIR="/usr/src/$MODULE_NAME-${VERSION}"

generate_keys() {
  cp -t $SIGN_DIR scripts/keys-setup.sh
  $SIGN_DIR/keys-setup.sh
}

ask_paths() {
  (read -rp "Enter the path of the public key: " PUB_KEY && [[ -f "$PUB_KEY" ]]) || return 1
  (read -rp "Enter the path of the private key: " PRIV_KEY && [[ -f "$PRIV_KEY" ]]) || return 1
}

cleanup() {
  rm -f new_dkms.conf
}
trap cleanup EXIT

if ! (dkms status 2>/dev/null | grep -q "$MODULE_NAME/${VERSION}.*installed"); then # If the module is already installed in DKMS
  cp dkms.conf new_dkms.conf
  sed -i "s/\$VERSION/${VERSION}/g" new_dkms.conf

  if [[ $(mokutil --sb-state 2>/dev/null) == *"enabled"* ]]; then                                              # If Secure boot is enabled
    if [[ -n "$(mokutil --list-enrolled 2>/dev/null)" ]]; then                                                 # If any keys are enrolled
      if [[ $(mokutil --test-key "$SIGN_DIR/MOK.der" 2>/dev/null) != *"already enrolled"* ]]; then             # If our keys are not already generated/enrolled by the MOK
        read -rp "Do you want to select your own enrolled keys? (y/N) " RES
        case $RES in
        [yY]*)
          PUB_KEY=
          PRIV_KEY=
          while ! ask_paths; do echo "Please provide valid paths"; done
          ;;
        *)
          generate_keys
          ;;
        esac
      fi
    else
      generate_keys
    fi
    echo "POST_BUILD=\"../../../../../../../$SIGN_DIR/sign-modules.sh ../\$kernelver/\$arch/module/*.ko*\"" >>new_dkms.conf
    mkdir -p $SIGN_DIR
    cp -t $SIGN_DIR scripts/sign-modules.sh

    if [[ -n $PUB_KEY ]] && [[ -n $PRIV_KEY ]]; then
      sed -i -e "s/PUB_KEY=.*/PUB_KEY=$PUB_KEY/" -e "s/PRIV_KEY=.*/PRIV_KEY=$PRIV_KEY/" "$SIGN_DIR/sign-modules.sh"
    fi
  fi

  if [[ ! -d "$MOD_SRC_DIR" ]]; then
    mkdir -p "$MOD_SRC_DIR"
    cp -R "$PWD/src/" "$MOD_SRC_DIR/src"
  fi

  mv new_dkms.conf "$MOD_SRC_DIR/dkms.conf"
  dkms add -m $MODULE_NAME -v "${VERSION}"
  dkms install -m $MODULE_NAME -v "${VERSION}"

  # module auto-loading
  echo "# Load the acpi_ec module" >> /etc/modules-load.d/modules.conf
  echo "acpi_ec" >> /etc/modules-load.d/modules.conf

else
  echo "$MODULE_NAME v${VERSION} is already installed"
  exit 1
fi
