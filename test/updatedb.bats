#!/usr/bin/env bats
load common.sh

@test "configures updatedb" {
  create_machines_yaml <<MACHINES_YAML
machines:
  test.example.com: {}
MACHINES_YAML
  compile 'test.example.com'
  assert_successful

  assert_output_matching '/^# BEGIN: updatedb/,/^# END: updatedb/' <<"EXPECTED"
if [ -f /etc/updatedb.conf ]; then
  . /etc/updatedb.conf
  if [ "$PRUNEPATHS" == "${PRUNEPATHS/\/mnt/}" ]; then
    sed -i '/PRUNEPATHS/c\PRUNEPATHS="'"$PRUNEPATHS /mnt"'"' /etc/updatedb.conf
  fi
  if [ "$PRUNEFS" == "${PRUNEFS/aufs/}" ]; then
    sed -i '/PRUNEFS/c\PRUNEFS="'"$PRUNEFS aufs"'"' /etc/updatedb.conf
  fi
fi
EXPECTED
}
