#!/usr/bin/env sh
set -eu

claude plugin marketplace add 0x0w1/jig --scope project
claude plugin install jig@jig --scope project
