#!/usr/bin/env bats
load common.sh

@test "disables password authentication" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com: {}
MACHINES_YAML

  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: ssh_password_authentication$/,/^# END: ssh_password_authentication$/' <<EXPECTED
if ! grep -qi '^PasswordAuthentication no' /etc/ssh/sshd_config; then
  sed -i '/^PasswordAuthentication/Id' /etc/ssh/sshd_config
  echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config
  systemctl reload ssh.service
fi
EXPECTED

}
