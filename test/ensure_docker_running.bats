#!/usr/bin/env bats
load common.sh

@test "ensures docker is running for application servers" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com: {}
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: ensure_docker_running$/,/^# END: ensure_docker_running$/' <<EXPECTED
if [ -f /lib/systemd/system/docker.service ]; then
  systemctl start docker.service
fi
EXPECTED
}
