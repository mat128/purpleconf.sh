#!/usr/bin/env bats
load common.sh

@test "installs apt-metrics tooling" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com: {}
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: apt-metrics$/,/^# END: apt-metrics$/' <<"EXPECTED"
ensure_installed update-notifier-common
cat <<"DATA" > /usr/local/sbin/apt-metrics
#!/bin/bash -e
APT_CHECK=$(/usr/lib/update-notifier/apt-check 2>&1 1>/dev/null)
APT_CHECK_FAILED=$?

UPDATES=$(echo "$APT_CHECK" | cut -d ';' -f 1)
SECURITY=$(echo "$APT_CHECK" | cut -d ';' -f 2)
REBOOT=$([ -f /var/run/reboot-required ] && echo 1 || echo 0)

cat <<STATUS
# HELP apt_check_failed Apt package pending check failed
# TYPE apt_check_failed gauge
apt_check_failed ${APT_CHECK_FAILED}
STATUS

if [ "$APT_CHECK_FAILED" -eq 0 ]; then
  cat <<STATUS
# HELP apt_upgrades_pending Apt package pending updates by origin.
# TYPE apt_upgrades_pending gauge
apt_upgrades_pending ${UPDATES}

# HELP apt_security_upgrades_pending Apt package pending security updates by origin.
# TYPE apt_security_upgrades_pending gauge
apt_security_upgrades_pending ${SECURITY}
STATUS
fi

cat <<STATUS
# HELP node_reboot_required Node reboot is required for software updates.
# TYPE node_reboot_required gauge
node_reboot_required ${REBOOT}
STATUS
DATA

chmod +x /usr/local/sbin/apt-metrics

mkdir -p /var/lib/node_exporter/textfile_collector
cat <<DATA > /etc/apt/apt.conf.d/60prometheus-metrics
APT::Update::Post-Invoke-Success {
  "/usr/local/sbin/apt-metrics > /var/lib/node_exporter/textfile_collector/apt.prom || true"
};

DPkg::Post-Invoke {
  "/usr/local/sbin/apt-metrics > /var/lib/node_exporter/textfile_collector/apt.prom || true"
};
DATA
EXPECTED
}

@test "removes previously configured metrics when monitoring via node_exporter" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com:
     monitoring:
        type: node_exporter
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: apt-metrics$/,/^# END: apt-metrics$/' <<EXPECTED
rm -f /etc/apt/apt.conf.d/60prometheus-metrics
rm -f /usr/local/sbin/apt-metrics
rm -rf /var/lib/node_exporter/textfile_collector
EXPECTED
}