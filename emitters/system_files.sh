#!/bin/bash -eu
pushd "$(dirname $0)" >/dev/null
. ../config.sh
popd >/dev/null

files_count="$(config "system.files" | count)"

if [ "${files_count}" -eq 0 ]; then
  exit 0
fi

echo "# BEGIN: system_files"
files_index="$(range "$files_count")"
for i in $files_index; do
  path_to_file=$(config "system.files | .$i.path" | value)
  cat <<SYSTEM_FILE
cat <<EOF > ${path_to_file}
$(config "system.files | .$i.contents" | value)
EOF

SYSTEM_FILE
done
echo "# END: system_files"
