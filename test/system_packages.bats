#!/usr/bin/env bats
load common.sh

@test "installs additional specified system packages" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com:
    system:
      packages:
        - net-tools
        - netcat
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: system_packages$/,/^# END: system_packages$/' <<EXPECTED
ensure_installed net-tools
ensure_installed netcat
EXPECTED
}


@test "does not emit any statement when unconfigured" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com: {}
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_does_not_contain 'system_packages'
}

