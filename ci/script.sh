#!/bin/bash
# ex: sts=2 sw=2 ts=2 et
# `script` phase: you usually build, test and generate docs in this phase

set -ex -o pipefail

. "$(dirname "$0")/common.sh"

export PKG_CONFIG_ALLOW_CROSS=1

run_cargo build

if $RUN_COMPAT; then
  run_cargo test
  run_cargo bench
else
  # build tests but don't run them
  run_cargo test --no-run

  # run tests in emulator
  find "target/$TARGET/debug" -maxdepth 1 -executable -type f -fprintf /dev/stderr "test: %p" -execdir qemu-$TARGET_ARCH -L /usr/$TARGET_ARCH-$TARGET_OS \;
fi
