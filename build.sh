#!/usr/bin/env bash
set -euxo pipefail

# Install latest brew
if [[ $(command -v brew) == "" ]]; then
    echo "Installing brew in order to build MetaCall"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Select the build type
if [ "${1:-}" == "debug" ]; then
    echo "Build Mode: Debug"

    # Replace the build type by debug
    sed -i '' '/-DCMAKE_BUILD_TYPE=/c\
      -DCMAKE_BUILD_TYPE=Debug
' metacall.rb

    # TODO: Add support for preloading address sanitizer in executables using MetaCall
#     sed -i '' '/-DCMAKE_BUILD_TYPE=Debug/a\
#       -DOPTION_BUILD_ADDRESS_SANITIZER=ON
# ' metacall.rb

    # Debug print the recipe
    cat metacall.rb

elif [ "${1:-}" == "release" ] || [ -z "${1:-}" ]; then
    echo "Build Mode: Release"
else
    echo "Error: Invalid mode. Please use 'debug' or 'release'."
    exit 1
fi

# Build metacall brew recipe
export HOMEBREW_NO_AUTO_UPDATE=1
brew tap-new metacall/core
mv ./metacall.rb $(brew --repository)/Library/Taps/metacall/homebrew-core/Formula/metacall.rb
brew install --formula metacall/core/metacall --overwrite --verbose
