#!/bin/bash
# This script was partly inspired by dop3j0e (https://gist.github.com/dop3j0e/2a9e2dddca982c4f679552fc1ebb18df)

DIR=$(dirname "$0")

cleanup() {
   mokutil --revoke-import
   rm -rf "$DIR"
   exit 1
}
trap cleanup SIGINT

echo
echo "Generating a new key for MOK..."
read -rp "Do you want to set a passphrase with the key ? (Y/n) " RES
echo

case $RES in
[nN]*)
   echo "This could introduce a security breach if the file is not correctly protected."
   echo "If an evil-minded person gain access to the key, he can sign his malicious code with it..."
   read -rp "Please press RETURN to go on."
   openssl req -nodes -new -x509 -newkey rsa:4096 -keyout "$DIR"/MOK.priv -outform DER -out "$DIR"/MOK.der -days 36500 -subj "/CN=$(hostname) module signing key/" || exit 1
   ;;

*)
   echo "This passphrase will be required everytime you want to sign a module."
   read -rp "Please press RETURN to go on."
   openssl req -new -x509 -newkey rsa:4096 -keyout "$DIR"/MOK.priv -outform DER -out "$DIR"/MOK.der -days 36500 -subj "/CN=$(hostname) module signing key/" || exit 1
   ;;
esac

echo "The generated key is going to be imported into the secure keystore."
echo "The following passphrase is only required once, during the following reboot."
read -rp "Please press RETURN to go on."

mokutil --import "$DIR"/MOK.der || exit 1

echo
echo "Please reboot your computer now to complete the enrollment of your new MOK."
echo "This is going to look somewhat similar to https://sourceware.org/systemtap/wiki/SecureBoot"
echo
