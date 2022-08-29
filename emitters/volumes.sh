#!/bin/bash -eu
pushd "$(dirname "$0")" >/dev/null
. ../config.sh
. _messages.sh
popd >/dev/null

decrypt_volume() {
  local volume="$1"
  local device="$2"
  local encryption_key="$3"

cat <<EOFF
ensure_installed cryptsetup
if cryptsetup status ${volume} | grep -q 'inactive'; then
  if cryptsetup isLuks ${device}; then
    echo '${encryption_key}' | cryptsetup --key-file - open ${device} ${volume}
  else
    $(render_message LUKS_INIT halt_intervention_required $device $encryption_key)
  fi
fi

EOFF
}


mount_volume() {
  local volume="$1"
  local device="$2"
  local filesystem="$3"

cat <<EOF
mkdir -p /mnt/external_storage/${volume}

if ! grep -q '/mnt/external_storage/${volume}' /etc/fstab; then
  echo "${device}   /mnt/external_storage/${volume} ${filesystem} defaults,noauto 0 0" >> /etc/fstab
fi

mountpoint -q /mnt/external_storage/${volume} || mount /mnt/external_storage/${volume}
EOF
}


mount_zpool() {
  local volume="$1"; shift
  local pool_members=("$@")

cat <<EOF
ensure_installed zfsutils-linux zfs-auto-snapshot
if ! zpool status ${volume}; then
  if ! zpool import ${volume}; then
    $(render_message ZPOOL_INIT halt_intervention_required $volume "${pool_members[@]}")
  fi
fi
EOF
}


indexed() {
  [ "$2" -gt 0 ] &&  echo "${1}_${2}" || echo "${1}"
}

zfs_create() {
  local name=$1
  local encryption=$2
  local encryption_passphrase=$3

  if [ -z "$encryption" ]; then
    echo "zfs create -p $name"
    return 0
  else
    echo "echo -n '$encryption_passphrase' | zfs create -p -o encryption=$encryption -o keylocation=prompt -o keyformat=passphrase $name"
    echo ""
  fi
}

for volume_name in $(config 'mounts' | keys); do
  device="$(config "mounts.${volume_name}.device" | value)"
  devices="$(config "mounts.${volume_name}.devices" | items)"
  devices="${devices:-"$device"}"

  encrypted="$(config "mounts.${volume_name}.encrypted" | default "false")"
  encryption_key="$(config "mounts.${volume_name}.encryption_key" | value)"

  filesystem=$(config "mounts.${volume_name}.filesystem" | default "ext4")
  folders="$(config "mounts.${volume_name}.folders" | items)"

  echo "# BEGIN: volumes_${volume_name}"

  index=0
  mountable_devices=()
  for device in $devices; do
    mountable_devices[$index]="$device"
    if $encrypted; then
      decrypted_name="$(indexed "${volume_name}" ${index})"
      mountable_devices[$index]="/dev/mapper/${decrypted_name}"
      decrypt_volume "$decrypted_name" "$device" "$encryption_key"
    fi
    index=$((index + 1))
  done

  if [ "$filesystem" == "zfs" ]; then
    mount_zpool "$volume_name" "${mountable_devices[@]}"
    for i in $(range $(config "mounts.${volume_name}.datasets" | count)); do
      dataset_short_name=$(config "mounts.${volume_name}.datasets | .$i.name" | value)
      dataset_mountpoint=$(config "mounts.${volume_name}.datasets | .$i.mountpoint" | value)
      dataset_compression=$(config "mounts.${volume_name}.datasets | .$i.compression" | value)
      dataset_encryption=$(config "mounts.${volume_name}.datasets | .$i.encryption" | value)
      dataset_encryption_passphrase=$(config "mounts.${volume_name}.datasets | .$i.encryption_passphrase" | value)
      dataset="$volume_name/$dataset_short_name"

      cat <<EOF
$(zfs_create "$dataset" "$dataset_encryption" "$dataset_encryption_passphrase")
if [ "\$(zfs get mountpoint -H -o value $dataset)" != "$dataset_mountpoint" ]; then
  zfs set mountpoint=$dataset_mountpoint $dataset
fi
EOF
      test -n "$dataset_compression" && cat <<EOF
if [ "\$(zfs get compression -H -o value $dataset)" != "$dataset_compression" ]; then
  zfs set compression=$dataset_compression $dataset
fi
EOF

      test -n "$dataset_encryption" && cat <<EOF
if [ "\$(zfs get keystatus -H -o value $dataset)" != "available" ]; then
  echo -n '$dataset_encryption_passphrase' | zfs load-key $dataset
fi
EOF
      cat <<EOF
if [ "\$(zfs get mounted -H -o value $dataset)" != "yes" ]; then
  zfs mount $dataset
fi
EOF

    done
  else
    mount_volume "$volume_name" "${mountable_devices[0]}" "$filesystem"
      for folder in $folders; do
        echo "mkdir -p /mnt/external_storage/$volume_name/$folder"
      done
  fi

  echo "# END: volumes_${volume_name}"
done
