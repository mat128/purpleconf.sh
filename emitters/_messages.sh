#!/bin/bash

__render_LUKS_INIT() {
  local device=$1
  local passphrase=$2

  cat - <<EOM
Device ${device} does not appear to be a LUKS device.
If you are initializing a new device, please format the LUKS container using the following command:
  echo '${passphrase}' | cryptsetup --key-file - luksFormat ${device}
WARNING: All data will be lost!
EOM
}

__render_ZPOOL_INIT() {
  local volume=$1; shift
  local pool_members=("$@")

  cat - <<EOM
${volume} does not appear to be a zpool.
If you are initializing a new device, please create a zpool using the following command:
  zpool create -O compression=lz4 -O atime=off ${volume} ${pool_members[@]}
EOM
}

render_message() {
  local key=$1; shift
  local handler=$1; shift

  cat - <<EOM
$handler <<"$key"
$(__render_${key} "$@")
$key
EOM
}