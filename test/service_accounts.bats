#!/usr/bin/env bats
load common.sh

@test "creates service accounts" {
    create_machines_yaml <<EOF
machines:
  test.example.com:
    access_control:
      authorized_keys_user: root
      authorized_keys: ""
      service_accounts:
        - username: qwerty
          home: /home/qwerty
          authorized_keys: |-
            ssh-rsa THE/PUB/KEY
            ssh-rsa OTHER/PUB/KEY
        - username: azerty
          home: /home/azerty
EOF
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: service_accounts/,/^# END: service_accounts$/' <<EXPECTED
# qwerty local account
if ! grep -q '^qwerty:' /etc/passwd; then
  adduser --disabled-password --gecos "" --home /home/qwerty qwerty
fi
if ! test -d /home/qwerty/.ssh; then
  mkdir -p /home/qwerty/.ssh
  chmod 0700 /home/qwerty/.ssh
fi

cat <<EOF > /home/qwerty/.ssh/authorized_keys
#
# This file is managed by an automated provisioning task. Any manual change will eventually be overwritten.
#
ssh-rsa THE/PUB/KEY
ssh-rsa OTHER/PUB/KEY
EOF
chmod 0644 /home/qwerty/.ssh/authorized_keys
chown -R qwerty:qwerty /home/qwerty/.ssh/
# azerty local account
if ! grep -q '^azerty:' /etc/passwd; then
  adduser --disabled-password --gecos "" --home /home/azerty azerty
fi
EXPECTED
}

@test "with no service accounts, nothing is configured" {
      create_machines_yaml <<EOF
machines:
  test.example.com: {}
EOF
  compile 'test.example.com'
  assert_successful

  assert_output_does_not_contain service_accounts
}
