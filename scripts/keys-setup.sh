#!/bin/bash
# This script was partly inspired by dop3j0e (https://gist.github.com/dop3j0e/2a9e2dddca982c4f679552fc1ebb18df)

DIR=$(dirname "$0")

cleanup() {
   mokutil --revoke-import
   exit 1
}
trap cleanup SIGINT

openssl req -nodes -new -x509 -newkey rsa:4096 -keyout "$DIR/mok.priv" -outform DER -out "$DIR/mok.der" -days 36500 -subj "/CN=$(cat /etc/hostname) module signing key/" || exit 1


echo "The generated key is going to be imported into the secure keystore."
echo "The following passphrase is only required once, during the following reboot."
read -rp "Please press RETURN to go on."

mokutil --import "$DIR/mok.der" || exit 1

echo
echo "Please reboot your computer now to complete the enrollment of your new MOK."
echo "This is going to look somewhat similar to https://sourceware.org/systemtap/wiki/SecureBoot"
