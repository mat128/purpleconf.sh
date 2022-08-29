#!/usr/bin/env bats
load common.sh

@test "skips unmanaged interfaces" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com:
    network:
      internal:
        interface: ens4
        managed: false
        ip: 172.16.88.11/24
        gateway: 172.16.88.1
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^cat <<INTERNAL.*/,/^INTERNAL$/' <<EXPECTED
EXPECTED
}

@test "disables cloud-init config when public is managed" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com:
    network:
      public:
        interface: ens4
        managed: true
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: networking_disable_cloud$/,/^# END: networking_disable_cloud$/' <<EXPECTED
echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
rm -f /etc/network/interfaces.d/50-cloud-init.cfg
EXPECTED
}

@test "keeps cloud-init config when public is unmanaged" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com:
    network:
      public:
        interface: ens4
        managed: false
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: networking_disable_cloud$/,/^# END: networking_disable_cloud$/' <<EXPECTED
rm -f /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
EXPECTED
}

@test "restarts networking after configuration" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com:
    network:
      public:
        interface: ens99
        managed: true
        state: down
      internal:
        interface: ens4
        managed: true
        ip: 172.16.10.11/24
        gateway: 172.16.10.1
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  # TODO assert this comes after reconfiguring the network.
  assert_output_matching '/^# BEGIN: NETWORKING_RELOAD$/,/^# END: NETWORKING_RELOAD$/' <<EXPECTED
if systemctl is-enabled ifup@ens99.service >/dev/null 2>&1; then
  systemctl stop ifup@ens99.service
fi
if systemctl is-enabled networking.service >/dev/null 2>&1; then
  systemctl restart networking.service
elif [ -d /etc/netplan ]; then
  netplan apply
else
  echo "Unsupported network manager." > /dev/stderr
  exit 1
fi
EXPECTED
}

@test "does not restart networking if all interfaces are unmanaged" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com:
    network:
      public:
        interface: ens99
        managed: false
      internal:
        interface: ens4
        managed: false
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  # TODO assert_output_empty?
  assert_output_matching '/^# BEGIN: NETWORKING_RELOAD$/,/^# END: NETWORKING_RELOAD$/' <<EXPECTED
EXPECTED
}

