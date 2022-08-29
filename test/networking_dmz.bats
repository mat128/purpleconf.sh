#!/usr/bin/env bats
load common.sh

given_machines() {
  cat <<MACHINES_YAML
machines:
  test.example.com:
    network:
      dmz:
        interface: ens4
        managed: true
        ip: 172.16.20.11/24
        routes:
          - net: 10.0.0.0/8
            gateway: 172.16.20.1
          - net: 20.1.1.0/24
            gateway: 172.16.20.2
          - net: 172.16.10.0/24
            gateway: 172.16.20.3
MACHINES_YAML
}

@test "configures legacy DMZ interface" {
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: LEGACY_99-dmz-network$/,/^# END: LEGACY_99-dmz-network$/' <<EXPECTED
if test -d /etc/network/interfaces.d; then
  cat <<EOF > /etc/network/interfaces.d/99-dmz-network.cfg
auto ens4
iface ens4 inet static
    address 172.16.20.11/24
    post-up ip route add 10.0.0.0/8 via 172.16.20.1 dev ens4
    pre-down ip route del 10.0.0.0/8
    post-up ip route add 20.1.1.0/24 via 172.16.20.2 dev ens4
    pre-down ip route del 20.1.1.0/24
    post-up ip route add 172.16.10.0/24 via 172.16.20.3 dev ens4
    pre-down ip route del 172.16.10.0/24
EOF
fi
EXPECTED
}

@test "configures netplan DMZ interface" {
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: NETPLAN_99-dmz-network$/,/^# END: NETPLAN_99-dmz-network$/' <<EXPECTED
if test -d /etc/netplan; then
  rm -f /etc/netplan/50-cloud-init.yaml
  cat <<EOF > /etc/netplan/99-dmz-network.yaml
network:
  version: 2
  ethernets:
    ens4:
      addresses:
        - 172.16.20.11/24
      routes:
        - to: 10.0.0.0/8
          via: 172.16.20.1
        - to: 20.1.1.0/24
          via: 172.16.20.2
        - to: 172.16.10.0/24
          via: 172.16.20.3
EOF
fi
EXPECTED
}
