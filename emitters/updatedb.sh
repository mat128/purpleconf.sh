#!/bin/bash
cat <<"EOF"
# BEGIN: updatedb
if [ -f /etc/updatedb.conf ]; then
  . /etc/updatedb.conf
  if [ "$PRUNEPATHS" == "${PRUNEPATHS/\/mnt/}" ]; then
    sed -i '/PRUNEPATHS/c\PRUNEPATHS="'"$PRUNEPATHS /mnt"'"' /etc/updatedb.conf
  fi
  if [ "$PRUNEFS" == "${PRUNEFS/aufs/}" ]; then
    sed -i '/PRUNEFS/c\PRUNEFS="'"$PRUNEFS aufs"'"' /etc/updatedb.conf
  fi
fi
# END: updatedb
EOF
