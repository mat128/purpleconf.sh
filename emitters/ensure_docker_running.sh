#!/bin/bash -eu
cat <<EOF
# BEGIN: ensure_docker_running
if [ -f /lib/systemd/system/docker.service ]; then
  systemctl start docker.service
fi
# END: ensure_docker_running
EOF