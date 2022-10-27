#!/usr/bin/env bats
load common.sh

@test "installs additional specified system packages" {
  create_machines_yaml <<"MACHINES_YAML"
machines:
  test.example.com:
    system:
      files:
        - path: /etc/test.conf
          contents: |
            [general]
            config=true
        - path: /etc/test2.conf
          contents: |-
            [[]][[]] {} $TEST
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: system_files$/,/^# END: system_files$/' <<"EXPECTED"
cat <<EOF > /etc/test.conf
[general]
config=true
EOF

cat <<EOF > /etc/test2.conf
[[]][[]] {} $TEST
EOF

EXPECTED
}


@test "does not emit any statement when unconfigured" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com: {}
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_does_not_contain 'system_files'
}

