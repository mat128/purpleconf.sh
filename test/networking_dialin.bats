#!/usr/bin/env bats
load common.sh

@test "configures legacy dialin interface" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com:
    network:
      dialin:
        interface: ens99
        managed: true
        mode: dhcp
        ip: 1.1.1.2/24
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: LEGACY_99-dialin-network$/,/^# END: LEGACY_99-dialin-network$/' <<EXPECTED
if test -d /etc/network/interfaces.d; then
  cat <<EOF > /etc/network/interfaces.d/99-dialin-network.cfg
auto ens99
iface ens99 inet dhcp
EOF
fi
EXPECTED
}

@test "configures netplan dialin interface" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com:
    network:
      dialin:
        interface: ens99
        managed: true
        mode: dhcp
        ip: 1.1.1.2/24
        gateway: 1.1.1.1
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: NETPLAN_99-dialin-network$/,/^# END: NETPLAN_99-dialin-network$/' <<EXPECTED
if test -d /etc/netplan; then
  rm -f /etc/netplan/50-cloud-init.yaml
  cat <<EOF > /etc/netplan/99-dialin-network.yaml
network:
  version: 2
  ethernets:
    ens99:
      dhcp4: true
EOF
fi
EXPECTED
}

@test "allows disabling legacy interface" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com:
    network:
      dialin:
        interface: ens99
        managed: true
        state: down
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: LEGACY_99-dialin-network$/,/^# END: LEGACY_99-dialin-network$/' <<EXPECTED
if test -d /etc/network/interfaces.d; then
  cat <<EOF > /etc/network/interfaces.d/99-dialin-network.cfg

iface ens99 inet manual
EOF
fi
EXPECTED
}

@test "allows disabling netplan interface" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com:
    network:
      dialin:
        interface: ens99
        managed: true
        state: down
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: NETPLAN_99-dialin-network$/,/^# END: NETPLAN_99-dialin-network$/' <<EXPECTED
if test -d /etc/netplan; then
  rm -f /etc/netplan/50-cloud-init.yaml
  cat <<EOF > /etc/netplan/99-dialin-network.yaml
network:
  version: 2
  ethernets:
    ens99:
EOF
fi
EXPECTED
}