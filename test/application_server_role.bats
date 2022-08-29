#!/usr/bin/env bats
load common.sh

@test "has no effect on servers without the application_server role" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com:
    roles:
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_does_not_contain application_server_role
}

@test "installs docker" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com:
    roles:
      - application_server
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: application_server_role$/,/^# END: application_server_role$/' <<EXPECTED
if ! test -e /usr/bin/dockerd; then
  ensure_installed docker.io docker-compose
fi
EXPECTED
}

@test "adds dependencies for all machine mounts" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com:
    roles:
      - application_server
    mounts:
      test_data:
        device: /dev/disk/by-id/12345
      test2_data:
        device: /dev/disk/by-id/67890
        filesystem: zfs
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: application_server_role$/,/^# END: application_server_role$/' <<"EXPECTED"
if ! test -e /usr/bin/dockerd; then
  ensure_installed docker.io docker-compose
fi
mkdir -p /etc/systemd/system/docker.service.d/
if ! test -f /etc/systemd/system/docker.service.d/$(systemd-escape -p --suffix=mount "/mnt/external_storage/test_data").conf; then
  cat <<DROP_IN > /etc/systemd/system/docker.service.d/$(systemd-escape -p --suffix=mount "/mnt/external_storage/test_data").conf
[Unit]
Requisite=$(systemd-escape -p --suffix=mount "/mnt/external_storage/test_data")
After=$(systemd-escape -p --suffix=mount "/mnt/external_storage/test_data")
DROP_IN
  systemctl daemon-reload
fi

if ! test -f /etc/systemd/system/docker.service.d/$(systemd-escape -p --suffix=mount $(zfs get mountpoint -H -o value test2_data)).conf; then
  cat <<DROP_IN > /etc/systemd/system/docker.service.d/$(systemd-escape -p --suffix=mount $(zfs get mountpoint -H -o value test2_data)).conf
[Unit]
Requisite=$(systemd-escape -p --suffix=mount $(zfs get mountpoint -H -o value test2_data))
After=$(systemd-escape -p --suffix=mount $(zfs get mountpoint -H -o value test2_data))
DROP_IN
  systemctl daemon-reload
fi

EXPECTED
}

