#!/usr/bin/env bats
load common.sh

@test "installs and configures node exporter" {
    create_machines_yaml <<EOF
machines:
  test.example.com:
    monitoring:
      type: node_exporter
      tls_ca: "MY CA CERT"
      tls_cert: "MY CERT CHAIN"
      tls_key: "MY CERT KEY"
EOF
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: monitoring$/,/^# END: monitoring$/' <<"EXPECTED"
ensure_installed prometheus-node-exporter

cat <<EOF > /etc/default/prometheus-node-exporter
ARGS="--collector.textfile.directory=/var/lib/prometheus/node-exporter --web.config=/etc/prometheus-node-exporter/web-config.yml"
EOF

if ! test -d /etc/prometheus-node-exporter/; then
  mkdir /etc/prometheus-node-exporter/
  chown -R prometheus:prometheus /etc/prometheus-node-exporter
fi

cat <<EOF > /etc/prometheus-node-exporter/web-config.yml
tls_server_config:
    cert_file: /etc/prometheus-node-exporter/cert.crt
    key_file: /etc/prometheus-node-exporter/cert.key
    client_auth_type: RequireAndVerifyClientCert
    client_ca_file: /etc/prometheus-node-exporter/ca.crt
EOF

cat <<EOF > /etc/prometheus-node-exporter/cert.crt
MY CERT CHAIN
EOF

cat <<EOF > /etc/prometheus-node-exporter/cert.key
MY CERT KEY
EOF

cat <<EOF > /etc/prometheus-node-exporter/ca.crt
MY CA CERT
EOF

if [ "$(sha256sum /usr/bin/prometheus-node-exporter | cut -f1 -d ' ')" != "ae6030f0bad626a1acc43e0698d227212bc5d71196fd0af79e24e662c0f1c561" ]; then
  curl -L https://github.com/prometheus/node_exporter/releases/download/v1.2.2/node_exporter-1.2.2.linux-amd64.tar.gz | tar -xvz --strip 1 -C /usr/bin node_exporter-1.2.2.linux-amd64/node_exporter
  mv /usr/bin/node_exporter /usr/bin/prometheus-node-exporter

  systemctl restart prometheus-node-exporter
fi
EXPECTED
}

@test "skips machines with no monitoring configuration" {
  create_machines_yaml <<EOF
machines:
  test.example.com: {}
EOF
  compile 'test.example.com'
  assert_successful

  assert_output_does_not_contain "monitoring"
}

@test "skips machines with type other than node_exporter" {
  create_machines_yaml <<EOF
machines:
  test.example.com:
    monitoring:
      type: something_else
EOF
  compile 'test.example.com'
  assert_successful

  assert_output_does_not_contain "monitoring"
}
