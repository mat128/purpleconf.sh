#!/bin/bash
set -euo pipefail
# Compile a (partial/full) configuration for a target machine.

# Source code is machine.yaml + compile flags (options, which targets, etc.)
# Produces a script which serves as some sort of intermediate representation (IR).

pushd "$(dirname $0)" > /dev/null
. ./config.sh
popd > /dev/null

export MACHINES_FILE=$1
export MACHINE_NAME=$2

ensure_exists ".machines.\"${MACHINE_NAME}\""

echo "#!/bin/bash"
echo "set -eu"

$(dirname $0)/emitters/common_tools.sh

$(dirname $0)/emitters/hostname.sh
$(dirname $0)/emitters/system_packages.sh
$(dirname $0)/emitters/system_files.sh

$(dirname $0)/emitters/swap.sh
$(dirname $0)/emitters/ssh_authorized_keys.sh
$(dirname $0)/emitters/volumes.sh

$(dirname $0)/emitters/networking.sh

$(dirname $0)/emitters/ensure_docker_running.sh

$(dirname $0)/emitters/ssh_password_authentication.sh

$(dirname $0)/emitters/apt-metrics.sh
$(dirname $0)/emitters/fail2ban.sh
$(dirname $0)/emitters/updatedb.sh

$(dirname $0)/emitters/monitoring.sh

$(dirname $0)/emitters/service_accounts.sh

$(dirname $0)/emitters/application_server_role.sh
