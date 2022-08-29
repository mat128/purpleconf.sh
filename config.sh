#!/bin/bash

_to_json() {
  # NOTE(mmitchell): This support both yq 3.4 and yq 4+
  yq -o=json "$1" 2>/dev/null || yq read -j "$1" 2>/dev/null
}

config_root() {
  _to_json "${MACHINES_FILE}" | jq "$@"
}

config_machine() {
  local machine=$1
  local key=$2

  config_root ".machines.\"${machine}\".$key"
}

config() {
  config_machine "${MACHINE_NAME}" "$@"
}

config_exists() {
  local key=$1

  config_root -e ".machines.\"${MACHINE_NAME}\".$key" 1>/dev/null 2>&1
}

ensure_exists() {
  local node=$1
  config_root -e "$node" > /dev/null
}

keys() {
  default "" | jq -r 'keys_unsorted[]'
}

items() {
  default "" | jq -r '.[]?'
}

value() {
  default ""
}

default() {
  jq -r '.' | sed "s/^null\$/$1/"
}

count() {
  jq -r length
}

# index-based access does not work with yq's explodeAnchor.
# to be implemented through jq instead.
range() {
  local length=$1

  if [ "$length" != "" ] && [ "$length" -gt 0 ]; then
    seq 0 $((length - 1)) | sed 's/\(.*\)/\[\1\]/g'
  fi
}
