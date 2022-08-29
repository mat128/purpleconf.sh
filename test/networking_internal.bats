#!/usr/bin/env bats
load common.sh

given_machines() {
  cat <<MACHINES_YAML
global_nameservers: &global_nameservers
  - 1.1.1.1
  - 4.2.2.1
  - 4.2.2.2
machines:
  test.example.com:
    network:
      internal:
        interface: ens4
        managed: true
        ip: 172.16.10.11/24
        nameservers: *global_nameservers
        routes:
          - net: 10.0.0.0/8
            gateway: 172.16.10.1
          - net: 20.1.1.0/24
            gateway: 172.16.10.1
          - net: 172.16.20.0/24
            gateway: 172.16.10.1
MACHINES_YAML
}

@test "configures legacy internal network" {
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: LEGACY_99-internal-network$/,/^# END: LEGACY_99-internal-network$/' <<EXPECTED
if test -d /etc/network/interfaces.d; then
  cat <<EOF > /etc/network/interfaces.d/99-internal-network.cfg
auto ens4
iface ens4 inet static
    address 172.16.10.11/24
    post-up ip route add 10.0.0.0/8 via 172.16.10.1 dev ens4
    pre-down ip route del 10.0.0.0/8
    post-up ip route add 20.1.1.0/24 via 172.16.10.1 dev ens4
    pre-down ip route del 20.1.1.0/24
    post-up ip route add 172.16.20.0/24 via 172.16.10.1 dev ens4
    pre-down ip route del 172.16.20.0/24
    dns-nameserver 1.1.1.1
    dns-nameserver 4.2.2.1
    dns-nameserver 4.2.2.2
EOF
fi
EXPECTED
}

@test "configures legacy gateway" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com:
    network:
      internal:
        interface: ens4
        managed: true
        ip: 172.16.10.11/24
        gateway: 172.16.10.1
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: LEGACY_99-internal-network$/,/^# END: LEGACY_99-internal-network$/' <<EXPECTED
if test -d /etc/network/interfaces.d; then
  cat <<EOF > /etc/network/interfaces.d/99-internal-network.cfg
auto ens4
iface ens4 inet static
    address 172.16.10.11/24
    gateway 172.16.10.1
EOF
fi
EXPECTED
}

@test "configures netplan gateway" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com:
    network:
      internal:
        interface: ens4
        managed: true
        ip: 172.16.10.11/24
        gateway: 172.16.10.1
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: NETPLAN_99-internal-network$/,/^# END: NETPLAN_99-internal-network$/' <<EXPECTED
if test -d /etc/netplan; then
  rm -f /etc/netplan/50-cloud-init.yaml
  cat <<EOF > /etc/netplan/99-internal-network.yaml
network:
  version: 2
  ethernets:
    ens4:
      addresses:
        - 172.16.10.11/24
      gateway4: 172.16.10.1
EOF
fi
EXPECTED
}


@test "configures netplan internal network interface" {
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: NETPLAN_99-internal-network$/,/^# END: NETPLAN_99-internal-network$/' <<EXPECTED
if test -d /etc/netplan; then
  rm -f /etc/netplan/50-cloud-init.yaml
  cat <<EOF > /etc/netplan/99-internal-network.yaml
network:
  version: 2
  ethernets:
    ens4:
      addresses:
        - 172.16.10.11/24
      nameservers:
          addresses:
            - 1.1.1.1
            - 4.2.2.1
            - 4.2.2.2
      routes:
        - to: 10.0.0.0/8
          via: 172.16.10.1
        - to: 20.1.1.0/24
          via: 172.16.10.1
        - to: 172.16.20.0/24
          via: 172.16.10.1
EOF
fi
EXPECTED
}

@test "configures dhclient's resolvers" {
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: internal_resolvers$/,/^# END: internal_resolvers$/' <<EXPECTED
sed -i '/^supersede domain-name-servers/d' /etc/dhcp/dhclient.conf
echo 'supersede domain-name-servers 1.1.1.1, 4.2.2.1, 4.2.2.2;' >> /etc/dhcp/dhclient.conf
EXPECTED
}