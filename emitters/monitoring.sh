#!/bin/bash -eu
pushd "$(dirname $0)" > /dev/null
. ../config.sh
popd > /dev/null

if [ "$(config "monitoring.type" | value)" != "node_exporter" ]; then
  exit 0
fi

# Use a newer node exporter to support client certificates.
# Node exporter 1.2.2 binary is a drop-in replacement to the binary provided by the prometheus-node-exporter package on Ubuntu 20.04.
cat <<NODE_EXPORTER
# BEGIN: monitoring
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
$(config "monitoring.tls_cert" | value)
EOF

cat <<EOF > /etc/prometheus-node-exporter/cert.key
$(config "monitoring.tls_key" | value)
EOF

cat <<EOF > /etc/prometheus-node-exporter/ca.crt
$(config "monitoring.tls_ca" | value)
EOF

if [ "\$(sha256sum /usr/bin/prometheus-node-exporter | cut -f1 -d ' ')" != "ae6030f0bad626a1acc43e0698d227212bc5d71196fd0af79e24e662c0f1c561" ]; then
  curl -L https://github.com/prometheus/node_exporter/releases/download/v1.2.2/node_exporter-1.2.2.linux-amd64.tar.gz | tar -xvz --strip 1 -C /usr/bin node_exporter-1.2.2.linux-amd64/node_exporter
  mv /usr/bin/node_exporter /usr/bin/prometheus-node-exporter

  systemctl restart prometheus-node-exporter
fi
# END: monitoring
NODE_EXPORTER
