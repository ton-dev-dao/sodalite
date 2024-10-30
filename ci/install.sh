#! /bin/bash
# `install` phase: install stuff needed for the `script` phase
set -ex -o pipefail

. "$(dirname "$0")/common.sh"

# Install rustup
curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain "$TRAVIS_RUST_VERSION"
if $CROSS; then
	rustup target add "$TARGET"
fi

# tell cargo which linker to use for cross compilation
mkdir -p .cargo
cat >.cargo/config <<EOF
[target.$TARGET]
linker = "$TARGET_CC"
EOF
