#!/bin/bash -eu
pushd "$(dirname $0)" >/dev/null
. ../config.sh
popd >/dev/null

if ! config "roles" | items | grep -q '^application_server$'; then
  exit 0
fi

cat <<EOF
# BEGIN: application_server_role
if ! test -e /usr/bin/dockerd; then
  ensure_installed docker.io docker-compose
fi
EOF

if config_exists "mounts"; then
  echo "mkdir -p /etc/systemd/system/docker.service.d/"
  for volume_name in $(config "mounts" | keys); do
    filesystem=$(config "mounts.${volume_name}.filesystem" | default "ext4")
    if [ "$filesystem" == "zfs" ]; then
      cat <<EOF
if ! test -f /etc/systemd/system/docker.service.d/\$(systemd-escape -p --suffix=mount \$(zfs get mountpoint -H -o value ${volume_name})).conf; then
  cat <<DROP_IN > /etc/systemd/system/docker.service.d/\$(systemd-escape -p --suffix=mount \$(zfs get mountpoint -H -o value ${volume_name})).conf
[Unit]
Requisite=\$(systemd-escape -p --suffix=mount \$(zfs get mountpoint -H -o value ${volume_name}))
After=\$(systemd-escape -p --suffix=mount \$(zfs get mountpoint -H -o value ${volume_name}))
DROP_IN
  systemctl daemon-reload
fi

EOF
    else
      mountpoint="/mnt/external_storage/${volume_name}"
      cat <<EOF
if ! test -f /etc/systemd/system/docker.service.d/\$(systemd-escape -p --suffix=mount "${mountpoint}").conf; then
  cat <<DROP_IN > /etc/systemd/system/docker.service.d/\$(systemd-escape -p --suffix=mount "${mountpoint}").conf
[Unit]
Requisite=\$(systemd-escape -p --suffix=mount "${mountpoint}")
After=\$(systemd-escape -p --suffix=mount "${mountpoint}")
DROP_IN
  systemctl daemon-reload
fi

EOF
    fi
  done
fi

echo "# END: application_server_role"