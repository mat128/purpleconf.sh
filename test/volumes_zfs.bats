#!/usr/bin/env bats
load common.sh

@test "handles zfs unencrypted volumes" {
  create_machines_yaml <<EOF
machines:
  test.example.com:
    mounts:
      my_other_volume:
        device: /dev/disk/by-id/scsi-magical-device
        filesystem: zfs
        encrypted: false
EOF
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: volumes_my_other_volume$/,/^# END: volumes_my_other_volume$/' <<EXPECTED
ensure_installed zfsutils-linux zfs-auto-snapshot
if ! zpool status my_other_volume; then
  if ! zpool import my_other_volume; then
    $(render_error_message ZPOOL_INIT halt_intervention_required my_other_volume /dev/disk/by-id/scsi-magical-device)
  fi
fi
EXPECTED
}

@test "creates and mounts datasets" {
  create_machines_yaml <<"EOF"
machines:
  test.example.com:
    mounts:
      my_other_volume:
        device: /dev/disk/by-id/scsi-magical-device
        filesystem: zfs
        datasets:
          - name: purpose1
            mountpoint: /mnt/whatever/purpose1
            compression: lz4
          - name: purpose2
            mountpoint: /mnt/whatever/something_else
            encryption: custom-algo
            encryption_passphrase: "abc$def"
EOF
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: volumes_my_other_volume$/,/^# END: volumes_my_other_volume$/' <<EXPECTED
ensure_installed zfsutils-linux zfs-auto-snapshot
if ! zpool status my_other_volume; then
  if ! zpool import my_other_volume; then
    $(render_error_message ZPOOL_INIT halt_intervention_required my_other_volume /dev/disk/by-id/scsi-magical-device)
  fi
fi
zfs create -p my_other_volume/purpose1
if [ "\$(zfs get mountpoint -H -o value my_other_volume/purpose1)" != "/mnt/whatever/purpose1" ]; then
  zfs set mountpoint=/mnt/whatever/purpose1 my_other_volume/purpose1
fi
if [ "\$(zfs get compression -H -o value my_other_volume/purpose1)" != "lz4" ]; then
  zfs set compression=lz4 my_other_volume/purpose1
fi
if [ "\$(zfs get mounted -H -o value my_other_volume/purpose1)" != "yes" ]; then
  zfs mount my_other_volume/purpose1
fi
echo -n 'abc\$def' | zfs create -p -o encryption=custom-algo -o keylocation=prompt -o keyformat=passphrase my_other_volume/purpose2
if [ "\$(zfs get mountpoint -H -o value my_other_volume/purpose2)" != "/mnt/whatever/something_else" ]; then
  zfs set mountpoint=/mnt/whatever/something_else my_other_volume/purpose2
fi
if [ "\$(zfs get keystatus -H -o value my_other_volume/purpose2)" != "available" ]; then
  echo -n 'abc\$def' | zfs load-key my_other_volume/purpose2
fi
if [ "\$(zfs get mounted -H -o value my_other_volume/purpose2)" != "yes" ]; then
  zfs mount my_other_volume/purpose2
fi
EXPECTED
}

@test "handles zfs on LUKS encrypted volumes" {
  create_machines_yaml <<EOF
machines:
  test.example.com:
    mounts:
      my_other_volume:
        device: /dev/disk/by-id/scsi-magical-device
        filesystem: zfs
        encrypted: true
        encryption_key: "hunter2"
EOF
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: volumes_my_other_volume$/,/^# END: volumes_my_other_volume$/' <<EXPECTED
ensure_installed cryptsetup
if cryptsetup status my_other_volume | grep -q 'inactive'; then
  if cryptsetup isLuks /dev/disk/by-id/scsi-magical-device; then
    echo 'hunter2' | cryptsetup --key-file - open /dev/disk/by-id/scsi-magical-device my_other_volume
  else
    $(render_error_message LUKS_INIT halt_intervention_required "/dev/disk/by-id/scsi-magical-device" "hunter2")
  fi
fi

ensure_installed zfsutils-linux zfs-auto-snapshot
if ! zpool status my_other_volume; then
  if ! zpool import my_other_volume; then
    $(render_error_message ZPOOL_INIT halt_intervention_required my_other_volume /dev/mapper/my_other_volume)
  fi
fi
EXPECTED
}

@test "handles zfs encrypted pool of multiple devices" {
  create_machines_yaml <<EOF
machines:
  test.example.com:
    mounts:
      my_other_volume:
        devices:
          - /dev/disk/by-id/scsi-first-device
          - /dev/disk/by-id/scsi-second-device
        filesystem: zfs
        encrypted: true
        pool: true
        encryption_key: "hunter2"
EOF
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: volumes_my_other_volume$/,/^# END: volumes_my_other_volume$/' <<EXPECTED
ensure_installed cryptsetup
if cryptsetup status my_other_volume | grep -q 'inactive'; then
  if cryptsetup isLuks /dev/disk/by-id/scsi-first-device; then
    echo 'hunter2' | cryptsetup --key-file - open /dev/disk/by-id/scsi-first-device my_other_volume
  else
    $(render_error_message LUKS_INIT halt_intervention_required "/dev/disk/by-id/scsi-first-device" "hunter2")
  fi
fi

ensure_installed cryptsetup
if cryptsetup status my_other_volume_1 | grep -q 'inactive'; then
  if cryptsetup isLuks /dev/disk/by-id/scsi-second-device; then
    echo 'hunter2' | cryptsetup --key-file - open /dev/disk/by-id/scsi-second-device my_other_volume_1
  else
    $(render_error_message LUKS_INIT halt_intervention_required "/dev/disk/by-id/scsi-second-device" "hunter2")
  fi
fi

ensure_installed zfsutils-linux zfs-auto-snapshot
if ! zpool status my_other_volume; then
  if ! zpool import my_other_volume; then
    $(render_error_message ZPOOL_INIT halt_intervention_required my_other_volume /dev/mapper/my_other_volume /dev/mapper/my_other_volume_1)
  fi
fi
EXPECTED
}

@test "prompts for manual zpool initialization" {
  create_machines_yaml <<EOF
machines:
  test.example.com:
    mounts:
      my_volume:
        devices:
          - /dev/sdy
          - /dev/sdz
        filesystem: zfs
EOF
  compile 'test.example.com'
  assert_successful

  assert_output_within_output_matching '/^# BEGIN: volumes_my_volume$/,/^# END: volumes_my_volume$/' '/halt_intervention_required <<"ZPOOL_INIT"/,/^ZPOOL_INIT/'<<EXPECTED
my_volume does not appear to be a zpool.
If you are initializing a new device, please create a zpool using the following command:
  zpool create -O compression=lz4 -O atime=off my_volume /dev/sdy /dev/sdz
EXPECTED
}
