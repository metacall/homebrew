# Homebrew MetaCall script

This is MetaCall's formula for Homebrew.

## Implementation

This brew formulae compiles MetaCall core for ARM64 and AMD64. The installation process has been optimized to install the dependencies in a dynamic way.

- Enhanced Python setup process
    - Support for detecting Python version and location dynamically.
    - Improved handling of Python paths for both macOS and Linux systems.

- Refined NodeJS installation
    - Installs node executable and other shared libraries separately instead of a brew dependency
    - Bash completion for NPM

- Enhanced Metacall launcher:
    - Added more robust path detection for metacallcli based on the dsitributable type

The final distributable is generated using a Homebrew extension [`brew-pkg`](https://github.com/metacall/brew-pkg). It generates a installable `.pkg` and a portable `.tgz` file. The fork includes some extra features which have been described below.

1. **Recursive library patching**: The function recursively processes linked libraries.

2. **Dynamic linking**: Uses `@executable_path` to create relative paths for dynamic linking.

3. **ELF file validation**: Checks if the target binary is a valid ELF (Executable and Linkable Format) file.

4. **Library dependency analysis**: Uses `otool -L` to identify linked libraries for the given binary.

5. **Path filtering**: Filters library paths to only process those within the specified prefix path.

6. **Relative path calculation**: Computes relative paths between the binary and its linked libraries.

7. **Library path updating**: Uses `install_name_tool` to update library paths in the binary.
