#!/usr/bin/env bash
set -euxo pipefail

brew test ./metacall.rb

echo "Testing Python port..."
metacall port-test.py | grep "works"
