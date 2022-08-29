#!/bin/bash -eu
cat <<EOF
# BEGIN: hostname
echo "${MACHINE_NAME}" > /etc/hostname
hostname ${MACHINE_NAME}

grep '^127.0.1.1' /etc/hosts | grep -q '${MACHINE_NAME}' || sed -i 's/^\(127.0.1.1\s.*\)/\1 ${MACHINE_NAME}/g' /etc/hosts
# END: hostname
EOF
