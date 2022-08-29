#!/bin/bash -eu
pushd "$(dirname $0)" > /dev/null
. ./config.sh
popd > /dev/null


export MACHINES_FILE=$1
pattern=$2

for machine in $(config_root ".machines" | keys | grep "$pattern"); do
  # shellcheck disable=SC2091
 $(config_machine $machine 'managed' | default 'true') && echo $machine || true
done
