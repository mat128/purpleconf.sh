#!/bin/bash -eu
pushd "$(dirname $0)" >/dev/null
. ./config.sh
popd >/dev/null

MACHINES_FILE="$1"
HOSTNAME_PATTERN="$2"
COMMANDS_FILE="$3"

for machine in $($(dirname $0)/list_machines.sh "$MACHINES_FILE" "$HOSTNAME_PATTERN"); do
  cat "$COMMANDS_FILE" | ssh -l "$(config_machine "$machine" 'credentials.username' | value)" \
    "${machine}" \
    sudo /bin/bash -vx 1> >(sed "s/^/$machine: /") 2> >(sed "s/^/$machine: /" 1>&2 2>/dev/null)
  echo "$machine: DONE"
done
