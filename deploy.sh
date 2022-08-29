#!/bin/bash -eu
pushd "$(dirname $0)" > /dev/null
. ./config.sh
popd > /dev/null

MACHINES_FILE="$1"
HOSTNAME_PATTERN="$2"
IDENTITY_FILE="${3:-""}"

IDENTITY_COMMAND=""

if [ "$IDENTITY_FILE" != "" ]; then
  IDENTITY_COMMAND="-i ${IDENTITY_FILE}"
fi

for machine in $($(dirname $0)/list_machines.sh "$MACHINES_FILE" "$HOSTNAME_PATTERN"); do
  $(dirname $0)/compile.sh "${MACHINES_FILE}" "${machine}" \
    | ssh -l "$(config_machine $machine 'credentials.username' | value)" $IDENTITY_COMMAND \
          "${machine}" \
          sudo /bin/bash -vx 1> >(sed "s/^/$machine: /") 2> >(sed "s/^/$machine: /" 1>&2 2>/dev/null)
  echo "$machine: OK"
done
