#!/usr/bin/env sh
set -eu

claude plugin marketplace add 0x0w1/spai --scope project
claude plugin install spai@spai --scope project
