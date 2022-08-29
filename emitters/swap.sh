#!/bin/bash -eu
pushd "$(dirname $0)" > /dev/null
. ../config.sh
popd > /dev/null

if [ "$(config "swap" | value)" == "" ]; then
  exit 0
fi

swap_size_mb=$(config "swap.size_mb" | value)

cat <<EOF
# BEGIN: swap
if ! test -f /swapfile; then
  fallocate -l ${swap_size_mb}M /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
fi

if ! grep -q '^/swapfile swap' /etc/fstab; then
  echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
fi

if ! swapon --show=name --noheadings | grep -q '^/swapfile\$'; then
  swapon /swapfile
fi

if ! grep -q '^vm.swappiness=' /etc/sysctl.conf; then
  echo 'vm.swappiness=10' >> /etc/sysctl.conf
  sysctl -p
fi
# END: swap
EOF