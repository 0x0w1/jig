#!/usr/bin/env sh
set -eu

curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target opencode --scope project
