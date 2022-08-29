#!/bin/bash
# shellcheck source=./../emitters/_messages.sh
. $BATS_TEST_DIRNAME/../emitters/_messages.sh

MACHINES_YAML="$(mktemp -d ${TMPDIR:-"/tmp"}/infratools.XXXXXXXX)/machines.yaml"

setup() {
  given_machines | create_machines_yaml
}

teardown() {
  rm -f "$MACHINES_YAML"
}

given_machines() {
  echo "machines:"
}

create_machines_yaml() {
  cat > "$MACHINES_YAML"
}

compile() {
  run $BATS_TEST_DIRNAME/../compile.sh $MACHINES_YAML "$@"
}

list_machines() {
  run $BATS_TEST_DIRNAME/../list_machines.sh $MACHINES_YAML "$@"
}

assert_output() {
  diff -au <(cat) <(echo "$output")
}

assert_output_contains() {
  if ! echo $output | grep -q "$@"; then
    echo "Output was:"
    echo "$output"
    return 1
  fi
}

assert_output_does_not_contain() {
  if echo $output | grep -q "$@"; then
    echo "Output was:"
    echo "$output"
    return 1
  fi
}

assert_output_matching() {
  diff -au <(cat) <(echo "$output" | awk "$@" | awk 'NR>2 {print last} {last=$0}')
}

assert_output_within_output_matching() {
  diff -au <(cat) <(echo "$output" | awk "$1" | awk "$2" | awk 'NR>2 {print last} {last=$0}')
}

fail() {
  echo -e "$@" > /dev/stderr
  return 1
}

assert_successful() {
  [ "$status" -eq 0 ] || fail "Exit code was $status. Output was\n$output"
}

assert_failed() {
  [ "$status" -eq 1 ] || fail "Exit code was $status. Output was\n$output"
}

render_error_message() {
  render_message "$@"
}