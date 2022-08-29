#!/bin/bash -eu
pushd "$(dirname $0)" > /dev/null
. ../config.sh
popd > /dev/null

if [ "$(config "access_control.service_accounts" | value)" == "" ] || [ "$(config "access_control.service_accounts" | count)" == "0" ]; then
    exit 0
fi

echo "# BEGIN: service_accounts"
iterator=$(range "$(config "access_control.service_accounts" | count)")

for index in $iterator; do
  username="$(config "access_control.service_accounts | .${index}.username" | value)"
  home_directory="$(config "access_control.service_accounts | .${index}.home" | value)"

cat <<CREATE_ACCOUNT
# ${username} local account
if ! grep -q '^${username}:' /etc/passwd; then
  adduser --disabled-password --gecos "" --home ${home_directory} ${username}
fi
CREATE_ACCOUNT

if config "access_control.service_accounts | .${index}" | keys | grep -q '^authorized_keys$'; then
  cat <<SSH_KEY
if ! test -d ${home_directory}/.ssh; then
  mkdir -p ${home_directory}/.ssh
  chmod 0700 ${home_directory}/.ssh
fi

cat <<EOF > ${home_directory}/.ssh/authorized_keys
#
# This file is managed by an automated provisioning task. Any manual change will eventually be overwritten.
#
$(config "access_control.service_accounts | .${index}.authorized_keys" | value)
EOF
chmod 0644 ${home_directory}/.ssh/authorized_keys
chown -R ${username}:${username} ${home_directory}/.ssh/
SSH_KEY
fi
done
echo "# END: service_accounts"
