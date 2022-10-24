#!/bin/bash -eu
pushd "$(dirname $0)" >/dev/null
. ../config.sh
popd >/dev/null

packages="$(config "system.packages" | items)"

if test -z "${packages}"; then
  exit 0
fi

echo "# BEGIN: system_packages"
for package in ${packages}; do
  echo "ensure_installed $package"
done
echo "# END: system_packages"
