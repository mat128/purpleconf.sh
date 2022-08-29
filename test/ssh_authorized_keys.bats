#!/usr/bin/env bats
load common.sh

given_machines() {
  cat <<EOF
ssh_keys: &ssh_keys |
  ssh-rsa 12345

machines:
  test.example.com:
    access_control:
      authorized_keys: *ssh_keys
      authorized_keys_additional: ssh-rsa 88888
      authorized_keys_user: ubuntu
EOF
}

@test "configures ssh authorized keys" {
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: ssh_authorized_keys$/,/^# END: ssh_authorized_keys$/' <<EXPECTED
mkdir -p "/home/ubuntu/.ssh"
cat <<EOF > /home/ubuntu/.ssh/authorized_keys
#
# This file is managed by an automated provisioning task. Any manual change will eventually be overwritten.
#
ssh-rsa 12345
ssh-rsa 88888
EOF
chmod 644 /home/ubuntu/.ssh/authorized_keys
EXPECTED

}
