#!/bin/bash -eu
cat <<"EOF"
ensure_apt_fresh() {
  if test -z "$(find /var/cache/apt/pkgcache.bin -mmin -60)"; then
    apt-get update -q
  fi
}

ensure_installed() {
  local packages=$*

  for package in $packages; do
    if ! dpkg -l $package | grep -q '^ii'; then
      ensure_apt_fresh
      DEBIAN_FRONTEND=noninteractive apt-get -y -q install $package
    fi
  done
}

halt_intervention_required() {
  echo "************************************************************"
  cat -
  echo "************************************************************"
  echo "PROCESS HALTED. Human intervention required"
  exit 101
}
EOF