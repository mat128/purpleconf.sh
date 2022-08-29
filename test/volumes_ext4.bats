#!/usr/bin/env bats
load common.sh

@test "handles ext4 unencrypted volumes" {
    create_machines_yaml <<EOF
machines:
  test.example.com:
    mounts:
      my_first_disk:
        device: /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_deadbeef-8888-1111-7
        encrypted: false
EOF
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: volumes_my_first_disk$/,/^# END: volumes_my_first_disk$/' <<EXPECTED
mkdir -p /mnt/external_storage/my_first_disk

if ! grep -q '/mnt/external_storage/my_first_disk' /etc/fstab; then
  echo "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_deadbeef-8888-1111-7   /mnt/external_storage/my_first_disk ext4 defaults,noauto 0 0" >> /etc/fstab
fi

mountpoint -q /mnt/external_storage/my_first_disk || mount /mnt/external_storage/my_first_disk
EXPECTED
}

@test "creates one directory per folder" {
  create_machines_yaml <<EOF
machines:
  test.example.com:
    mounts:
      my_first_disk:
        device: /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_deadbeef-8888-1111-7
        folders:
          - purpose1
          - purpose2
EOF
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: volumes_my_first_disk$/,/^# END: volumes_my_first_disk$/' <<EXPECTED
mkdir -p /mnt/external_storage/my_first_disk

if ! grep -q '/mnt/external_storage/my_first_disk' /etc/fstab; then
  echo "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_deadbeef-8888-1111-7   /mnt/external_storage/my_first_disk ext4 defaults,noauto 0 0" >> /etc/fstab
fi

mountpoint -q /mnt/external_storage/my_first_disk || mount /mnt/external_storage/my_first_disk
mkdir -p /mnt/external_storage/my_first_disk/purpose1
mkdir -p /mnt/external_storage/my_first_disk/purpose2
EXPECTED
}

@test "handles ext4 encrypted volumes" {
  create_machines_yaml <<"EOF"
machines:
  test.example.com:
    mounts:
      my_first_disk:
        device: /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_deadbeef-8888-1111-7
        encrypted: true
        encryption_key: "ABC!!D$EF-"
EOF
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: volumes_my_first_disk$/,/^# END: volumes_my_first_disk$/' <<EXPECTED
ensure_installed cryptsetup
if cryptsetup status my_first_disk | grep -q 'inactive'; then
  if cryptsetup isLuks /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_deadbeef-8888-1111-7; then
    echo 'ABC!!D\$EF-' | cryptsetup --key-file - open /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_deadbeef-8888-1111-7 my_first_disk
  else
    $(render_error_message LUKS_INIT halt_intervention_required "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_deadbeef-8888-1111-7" "ABC!!D\$EF-")
  fi
fi

mkdir -p /mnt/external_storage/my_first_disk

if ! grep -q '/mnt/external_storage/my_first_disk' /etc/fstab; then
  echo "/dev/mapper/my_first_disk   /mnt/external_storage/my_first_disk ext4 defaults,noauto 0 0" >> /etc/fstab
fi

mountpoint -q /mnt/external_storage/my_first_disk || mount /mnt/external_storage/my_first_disk
EXPECTED
}

@test "prompts for manual volume initialization" {
  create_machines_yaml <<"EOF"
machines:
  test.example.com:
    mounts:
      my_first_disk:
        device: /dev/whatever
        encrypted: true
        encryption_key: "ABC!!D$EF-"
EOF
  compile 'test.example.com'
  assert_successful

  assert_output_within_output_matching '/^# BEGIN: volumes_my_first_disk$/,/^# END: volumes_my_first_disk$/' '/halt_intervention_required <<"LUKS_INIT"/,/^LUKS_INIT/' <<"EXPECTED"
Device /dev/whatever does not appear to be a LUKS device.
If you are initializing a new device, please format the LUKS container using the following command:
  echo 'ABC!!D$EF-' | cryptsetup --key-file - luksFormat /dev/whatever
WARNING: All data will be lost!
EXPECTED
}
