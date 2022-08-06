#!/usr/bin/env bash
set -euxo pipefail
# INSTALL latest brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install ./metacall.rb --build-from-source -dv
brew test ./metacall.rb
