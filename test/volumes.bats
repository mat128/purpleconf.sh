#!/usr/bin/env bats
load common.sh

@test "handles machines with no volumes at all" {
  create_machines_yaml <<EOF
machines:
  test.example.com: {}
EOF
  compile 'test.example.com'
  assert_successful

  assert_output_does_not_contain "has no keys"
}
