#!/usr/bin/env bats
load common.sh

@test "fails when invoked with a missing machine" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com: {}
MACHINES_YAML

  compile "test2.example.com"
  assert_failed
}

@test "fails when invoked with an invalid yaml" {
    create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com:
    test: "wrong\zsequence"
MACHINES_YAML

  compile "test.example.com"
  assert_failed
}

@test "produces a script that runs in errexit and 'unset variables as errors' mode" {
    create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com: {}
MACHINES_YAML

    compile "test.example.com"

    assert_output_contains "set -eu"
}
