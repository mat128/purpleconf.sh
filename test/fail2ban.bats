#!/usr/bin/env bats
load common.sh

@test "installs fail2ban" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com: {}
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: fail2ban$/,/^# END: fail2ban$/' <<EXPECTED
ensure_installed fail2ban
EXPECTED
}
