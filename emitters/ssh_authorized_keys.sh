#!/bin/bash -eu
pushd "$(dirname $0)" > /dev/null
. ../config.sh
popd > /dev/null

if [ "$(config "access_control" | value)" == "" ]; then
  exit 0
fi

AUTHORIZED_KEYS_FILE="$(config 'access_control.authorized_keys_file' | value)"
AUTHORIZED_KEYS_USER="$(config 'access_control.authorized_keys_user' | value)"
AUTHORIZED_KEYS="$(config 'access_control.authorized_keys' | value)"
AUTHORIZED_KEYS_ADDITIONAL="$(config 'access_control.authorized_keys_additional' | value)"

if [ -z "$AUTHORIZED_KEYS_FILE" ]; then
  test -z "$AUTHORIZED_KEYS_USER" && exit 1
  AUTHORIZED_KEYS_FILE="/home/$AUTHORIZED_KEYS_USER/.ssh/authorized_keys"
fi

cat <<EOFF
# BEGIN: ssh_authorized_keys
mkdir -p "$(dirname $AUTHORIZED_KEYS_FILE)"
cat <<EOF > $AUTHORIZED_KEYS_FILE
#
# This file is managed by an automated provisioning task. Any manual change will eventually be overwritten.
#
$AUTHORIZED_KEYS
$AUTHORIZED_KEYS_ADDITIONAL
EOF
chmod 644 $AUTHORIZED_KEYS_FILE
# END: ssh_authorized_keys
EOFF
