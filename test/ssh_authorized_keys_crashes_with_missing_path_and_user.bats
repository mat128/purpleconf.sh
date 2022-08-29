#!/usr/bin/env bats
load common.sh

@test "crashes when missing path and user" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com:
    access_control:
      authorized_keys: ssh-rsa 9999
MACHINES_YAML

  compile 'test.example.com'
  assert_failed
}

@test "honors filename" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com:
    access_control:
      authorized_keys: ssh-rsa 9999
      authorized_keys_file: /root/.ssh/authorized_keys
MACHINES_YAML

  compile 'test.example.com'
  assert_output_contains "> /root/.ssh/authorized_keys"
}
