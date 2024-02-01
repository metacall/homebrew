#!/usr/bin/env bash
set -euxo pipefail

# Install latest brew
if [[ $(command -v brew) == "" ]]; then
    echo "Installing brew in order to build MetaCall"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Build metacall brew recipe
export HOMEBREW_NO_AUTO_UPDATE=1
brew install ./metacall.rb --build-from-source --overwrite --no-binaries -v
