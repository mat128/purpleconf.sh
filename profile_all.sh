#!/bin/bash -eu
pushd "$(dirname $0)" >/dev/null
. ./config.sh
popd >/dev/null

MACHINES_FILE="$1"
HOSTNAME_PATTERN="$2"

emit_header() {
  printf "%s" "$1"
  printf "\t"
}

emit_header "Machine name"
emit_header "Hostname (long)"
emit_header "Operating system"
emit_header "Kernel release"
emit_header "Apt"
emit_header "Reboot?"
emit_header "Date of last boot"
emit_header "Docker version"
emit_header "Docker-compose version"
printf "\n"

data_commands() {
  cat <<"EOF"
  hostname -f
  lsb_release -d -s
  uname -r
  test -f /usr/lib/update-notifier/apt-check && (/usr/lib/update-notifier/apt-check 2>&1; echo) || echo "-"
  test -f /var/run/reboot-required && echo "yes" || echo "no"
  uptime -s
  which docker >/dev/null && docker --version || echo "Docker not installed on this machine."
  which docker-compose >/dev/null && docker-compose --version || echo "Docker-compose not installed on this machine."
EOF
}

for machine in $($(dirname $0)/list_machines.sh "$MACHINES_FILE" "$HOSTNAME_PATTERN"); do
  printf "%s\t" "$machine"

  data_commands | ssh -l "$(config_machine "$machine" 'credentials.username' | value)" \
    "${machine}" \
    sudo /bin/bash | tr '\n' '\t'

  printf "\n"
done
