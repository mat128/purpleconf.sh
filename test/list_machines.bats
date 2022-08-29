#!/usr/bin/env bats
load common.sh

@test "list_machines_matching" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com: {}
  test2.example.com: {}
  test.example.net: {}
  unmanaged.example.com:
    managed: false
MACHINES_YAML

  list_machines 'example.com$'

  assert_output <<EOF
test.example.com
test2.example.com
EOF
}
