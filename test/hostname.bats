#!/usr/bin/env bats
load common.sh

given_machines() {
  cat <<EOF
machines:
  test.example.com: {}
EOF
}

@test "configures hostname" {
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: hostname$/,/^# END: hostname$/' <<EXPECTED
echo "test.example.com" > /etc/hostname
hostname test.example.com

grep '^127.0.1.1' /etc/hosts | grep -q 'test.example.com' || sed -i 's/^\(127.0.1.1\s.*\)/\1 test.example.com/g' /etc/hosts
EXPECTED
}
