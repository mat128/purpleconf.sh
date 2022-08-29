#!/bin/bash -eu
pushd "$(dirname $0)" >/dev/null
. ../config.sh
popd >/dev/null

emit_dhclient_internal_resolvers() {
  local network_name=$1
  local nameservers_as_list=""

  for nameserver in $(config "network.$network_name.nameservers" | items); do
    if [ "${nameservers_as_list:-}" == "" ]; then
      nameservers_as_list="${nameserver}"
    else
      nameservers_as_list="${nameservers_as_list}, ${nameserver}"
    fi
  done

  if [ "$nameservers_as_list" != "" ]; then
    cat <<OUTPUT
# BEGIN: internal_resolvers
sed -i '/^supersede domain-name-servers/d' /etc/dhcp/dhclient.conf
echo 'supersede domain-name-servers ${nameservers_as_list};' >> /etc/dhcp/dhclient.conf
# END: internal_resolvers
OUTPUT
  fi
}

emit_legacy() {
  local network_name=$1
  local key=$2

  local interface="$(config "network.$network_name.interface" | value)"
  local ip="$(config "network.$network_name.ip" | value)"
  local gateway="$(config "network.$network_name.gateway" | value)"
  local state="$(config "network.$network_name.state" | default "up")"
  local mode="$(config "network.$network_name.mode" | default "static")"

  if [ "$state" == "down" ]; then
    mode="manual"
  fi

  cat <<OUTPUT
# BEGIN: LEGACY_${key}
if test -d /etc/network/interfaces.d; then
  cat <<EOF > /etc/network/interfaces.d/${key}.cfg
$([ $state != "down" ] && echo "auto ${interface}")
iface ${interface} inet ${mode}
OUTPUT
  if [ $mode == "static" ]; then
    cat <<OUTPUT
    address ${ip}
OUTPUT
    if [ "$gateway" != "" ]; then
      echo "    gateway ${gateway}"
    fi
  fi
  for i in $(range "$(config "network.$network_name.routes" | count)"); do
    network=$(config "network.$network_name.routes | .$i.net" | value)
    gateway=$(config "network.$network_name.routes | .$i.gateway" | value)
    cat <<OUTPUT
    post-up ip route add ${network} via ${gateway} dev ${interface}
    pre-down ip route del ${network}
OUTPUT
  done

  for nameserver in $(config "network.$network_name.nameservers" | items); do
    cat <<OUTPUT
    dns-nameserver ${nameserver}
OUTPUT
  done
  cat <<OUTPUT
EOF
fi
# END: LEGACY_${key}
OUTPUT
}

emit_netplan() {
  local network_name=$1
  local key=$2

  local interface="$(config "network.$network_name.interface" | value)"
  local ip="$(config "network.$network_name.ip" | value)"
  local gateway="$(config "network.$network_name.gateway" | value)"
  local state="$(config "network.$network_name.state" | default "up")"
  local mode="$(config "network.$network_name.mode" | default "static")"

  if [ "$state" == "down" ]; then
    mode="manual"
  fi

  cat <<OUTPUT
# BEGIN: NETPLAN_${key}
if test -d /etc/netplan; then
  rm -f /etc/netplan/50-cloud-init.yaml
  cat <<EOF > /etc/netplan/${key}.yaml
network:
  version: 2
  ethernets:
    ${interface}:
OUTPUT
  if [ $mode == "dhcp" ]; then
    cat <<OUTPUT
      dhcp4: true
OUTPUT
  fi
  if [ "$mode" == "static" ]; then
    cat <<OUTPUT
      addresses:
        - ${ip}
OUTPUT
    if [ "$gateway" != "" ]; then
      echo "      gateway4: ${gateway}"
    fi
  fi

  if config_exists "network.$network_name.nameservers"; then
    cat <<OUTPUT
      nameservers:
          addresses:
OUTPUT

    for nameserver in $(config "network.$network_name.nameservers" | items); do
      cat <<OUTPUT
            - ${nameserver}
OUTPUT
    done
  fi

  routes_index="$(range "$(config "network.$network_name.routes" | count)")"
  if [ "$routes_index" != "" ]; then
    cat <<OUTPUT
      routes:
OUTPUT
    for i in $routes_index; do
      network=$(config "network.$network_name.routes | .$i.net" | value)
      gateway=$(config "network.$network_name.routes | .$i.gateway" | value)
      cat <<OUTPUT
        - to: ${network}
          via: ${gateway}
OUTPUT
    done
  fi

  cat <<OUTPUT
EOF
fi
# END: NETPLAN_${key}
OUTPUT
}

configure_network() {
  local network_name=$1
  local key=$2

  [ -n "$(config "network.$network_name" | value)" ] || return 0
  [ "$(config "network.$network_name.managed" | value)" == "true" ] || return 0

  emit_dhclient_internal_resolvers $network_name
  emit_legacy $network_name $key
  emit_netplan $network_name $key
}

disable_cloud_config() {
  echo "# BEGIN: networking_disable_cloud"

  if [ "$(config "network.public.managed" | value)" == "true" ]; then
    echo "echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
    echo "rm -f /etc/network/interfaces.d/50-cloud-init.cfg"
  else
    echo "rm -f /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
  fi

  echo "# END: networking_disable_cloud"
}

reload_network() {
  echo "# BEGIN: NETWORKING_RELOAD"
  local any_managed_network=false
  for network_name in $(config "network" | keys); do
    if [ "$(config "network.${network_name}.managed" | value)" == "true" ]; then
      any_managed_network=true
    fi

    if [ "$(config "network.${network_name}.state" | value)" == "down" ]; then
      interface="$(config "network.${network_name}.interface" | value)"
      cat <<OUTPUT
if systemctl is-enabled ifup@${interface}.service >/dev/null 2>&1; then
  systemctl stop ifup@${interface}.service
fi
OUTPUT
    fi
  done

  if [ "$any_managed_network" == "true" ]; then
    cat <<EOF
if systemctl is-enabled networking.service >/dev/null 2>&1; then
  systemctl restart networking.service
elif [ -d /etc/netplan ]; then
  netplan apply
else
  echo "Unsupported network manager." > /dev/stderr
  exit 1
fi
EOF
  fi
  echo "# END: NETWORKING_RELOAD"
}

if [ "$(config 'network')" == "" ]; then
  exit 0
fi

configure_network 'dmz' '99-dmz-network'
configure_network 'internal' '99-internal-network'
configure_network 'public' '99-wan-network'
configure_network 'dialin' '99-dialin-network'
disable_cloud_config
reload_network
