#!/bin/bash
set -eu

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y -q upgrade --with-new-pkgs