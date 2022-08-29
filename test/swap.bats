#!/usr/bin/env bats
load common.sh

@test "configures swap" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com:
    swap:
      size_mb: 1024
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: swap/,/^# END: swap/' <<"EXPECTED"
if ! test -f /swapfile; then
  fallocate -l 1024M /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
fi

if ! grep -q '^/swapfile swap' /etc/fstab; then
  echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
fi

if ! swapon --show=name --noheadings | grep -q '^/swapfile$'; then
  swapon /swapfile
fi

if ! grep -q '^vm.swappiness=' /etc/sysctl.conf; then
  echo 'vm.swappiness=10' >> /etc/sysctl.conf
  sysctl -p
fi
EXPECTED
}

# custom filename

@test "without swap" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com: {}
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_does_not_contain swap
}
