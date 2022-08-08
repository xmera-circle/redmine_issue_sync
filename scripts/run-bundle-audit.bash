#!/usr/bin/env bash

set -e

cd "${0%/*}/.."

echo "Running bundle audit"
bundle audit update
bundle audit
