class Metacall < Formula
  desc "Ultimate polyglot programming experience"
  homepage "https://metacall.io"
  url "https://github.com/metacall/core/archive/refs/tags/v0.8.3.tar.gz"
  sha256 "beb73c5e8838d2838074d7cbc256453bade2d7f836b38f249d1a06930818cbc6"
  license "Apache-2.0"
  head "https://github.com/metacall/core.git", branch: "develop"

  depends_on "cmake" => :build
  depends_on "python@3.12"
  depends_on "ruby@3.3"
  # TODO: Enable Java
  # depends_on "openjdk"

  # Define NodeJS resource
  if OS.mac? && Hardware::CPU.intel?
    resource "node" do
      url "https://github.com/metacall/libnode/releases/download/v22.6.0/libnode-amd64-macos.tar.xz"
      sha256 "aa62ed6bb5b85c57fc58850540c66953302982bda46300056705035400d65967"
    end
  end

  if OS.mac? && Hardware::CPU.arm?
    resource "node" do
      url "https://github.com/metacall/libnode/releases/download/v22.6.0/libnode-arm64-macos.tar.xz"
      sha256 "26c661e9a8e553614e719644f05bb46ffa397e85b658aa9853257f65f8ea9270"
    end
  end

  # We track major/minor from upstream Node releases.
  # We will accept *important* npm patch releases when necessary.
  resource "npm" do
    url "https://registry.npmjs.org/npm/-/npm-10.8.2.tgz"
    sha256 "c8c61ba0fa0ab3b5120efd5ba97fdaf0e0b495eef647a97c4413919eda0a878b"
  end

  def python
    deps.map(&:to_formula)
        .find { |f| f.name.match?(/^python@\d\.\d+$/) }
  end

  # Get Python location
  def python_executable
    python.opt_libexec/"bin/python"
  end

  def install
    # Build path
    build_dir = buildpath/"build"
    Dir.mkdir(build_dir)
    Dir.chdir(build_dir)

    # Set Python
    py3ver = Language::Python.major_minor_version python_executable
    py3prefix = if OS.mac?
      python.opt_frameworks/"Python.framework/Versions"/py3ver
    else
      python.opt_prefix
    end
    py3include = py3prefix/"include/python#{py3ver}"
    py3rootdir = py3prefix
    py3lib = py3prefix/"lib/libpython#{py3ver}.dylib"

    # Set NodeJS
    resource("node").stage do
      build_dir.install resource("node")
      bin.install build_dir/"node"
      lib.install build_dir/"libnode.127.dylib"
    end

    # Add build folder to PATH in order to find node executable
    ENV.prepend_path "PATH", bin

    # Set NPM
    bootstrap = buildpath/"npm_bootstrap"
    bootstrap.install resource("npm")
    # These dirs must exists before npm install.
    mkdir_p libexec/"lib"
    system "node", bootstrap/"bin/npm-cli.js", "install", "-ddd", "--global",
            "--prefix=#{libexec}", resource("npm").cached_download

    # The `package.json` stores integrity information about the above passed
    # in `cached_download` npm resource, which breaks `npm -g outdated npm`.
    # This copies back over the vanilla `package.json` to fix this issue.
    cp bootstrap/"package.json", libexec/"lib/node_modules/npm"
    # These symlinks are never used & they've caused issues in the past.
    rm_r libexec/"share" if (libexec/"share").exist?

    bash_completion.install bootstrap/"lib/utils/completion.sh" => "npm"

    # Link NPM modules into bin
    ln_sf libexec/"lib/node_modules/npm/bin/npm-cli.js", bin/"npm"
    ln_sf libexec/"lib/node_modules/npm/bin/npx-cli.js", bin/"npx"

    # Set the compiler
    cc_compiler = `xcrun --find clang`.tr("\n","")
    cxx_compiler = `xcrun --find clang++`.tr("\n","")
    xcode_prefix = `xcode-select -p`.tr("\n","")
    ENV["SDKROOT"] = `xcrun --show-sdk-path`.tr("\n","")
    ENV["MACOSX_DEPLOYMENT_TARGET"] = ""

    args = std_cmake_args + %W[
      -Wno-dev
      -DCMAKE_C_COMPILER=#{cc_compiler}
      -DCMAKE_CXX_COMPILER=#{cxx_compiler}
      -DCMAKE_INCLUDE_PATH=#{xcode_prefix}/usr/include/c++/v1
      -DCMAKE_BUILD_TYPE=Release
      -DOPTION_BUILD_SECURITY=OFF
      -DOPTION_FORK_SAFE=OFF
      -DOPTION_BUILD_SCRIPTS=OFF
      -DOPTION_BUILD_TESTS=OFF
      -DOPTION_BUILD_EXAMPLES=OFF
      -DOPTION_BUILD_LOADERS_PY=ON
      -DOPTION_BUILD_LOADERS_NODE=ON
      -DNodeJS_CMAKE_DEBUG=ON
      -DNodeJS_LIBRARY=#{lib}/libnode.127.dylib
      -DNodeJS_EXECUTABLE=#{bin}/node
      -DNPM_ROOT=#{bin}
      -DOPTION_BUILD_LOADERS_JAVA=OFF
      -DOPTION_BUILD_LOADERS_JS=OFF
      -DOPTION_BUILD_LOADERS_C=OFF
      -DOPTION_BUILD_LOADERS_COB=OFF
      -DOPTION_BUILD_LOADERS_CS=OFF
      -DOPTION_BUILD_LOADERS_RB=ON
      -DOPTION_BUILD_LOADERS_TS=ON
      -DOPTION_BUILD_LOADERS_FILE=ON
      -DOPTION_BUILD_PORTS=ON
      -DOPTION_BUILD_PORTS_PY=ON
      -DOPTION_BUILD_PORTS_NODE=ON
      -DOPTION_BUILD_PLUGINS_BACKTRACE=OFF
      -DPython3_VERSION=#{py3ver}
      -DPython3_ROOT_DIR=#{py3rootdir}
      -DPython3_EXECUTABLE=#{python_executable}
      -DPython3_LIBRARIES=#{py3lib}
      -DPython3_INCLUDE_DIR=#{py3include}
    ]

    system "cmake", *args, ".."
    system "cmake", "--build", ".", "--target", "install"

    shebang = "\#!/usr/bin/env bash\n"
    # debug = "set -euxo pipefail\n"

    metacall_extra = [
      "SCRIPT_DIR=$(cd -- \"$(dirname -- \"${BASH_SOURCE[0]}\")\" &> /dev/null && pwd)\n",
      "PARENT=$(dirname \"${SCRIPT_DIR}\")\n",
      "if [ -f \"${PARENT}/metacallcli\" ]; then\n",
      "  PREFIX=\"${PARENT}\"\n",
      "else\n",
      "  PREFIX=\"${PARENT}/Cellar/metacall/#{version}\"\n",
      "fi\n",
      "export LOADER_LIBRARY=\"${PREFIX}/lib\"\n",
      "export SERIAL_LIBRARY_PATH=\"${PREFIX}/lib\"\n",
      "export DETOUR_LIBRARY_PATH=\"${PREFIX}/lib\"\n",
      "export PORT_LIBRARY_PATH=\"${PREFIX}/lib\"\n",
      "export CONFIGURATION_PATH=\"${PREFIX}/configurations/global.json\"\n",
    ]
    cmds = [shebang, *metacall_extra]
    cmds.append("export LOADER_SCRIPT_PATH=\"\${LOADER_SCRIPT_PATH:-\`pwd\`}\"\n")
    cmds.append("${PREFIX}/metacallcli $@\n")

    File.open("metacall.sh", "w") do |f|
      f.write(*cmds)
    end

    chmod("u+x", "metacall.sh")
    bin.install "metacall.sh" => "metacall"

    # Clean build data
    system "cmake", "--build", ".", "--target", "clean"
  end

  # # NPM Post Install
  # def post_install
  #   node_modules = HOMEBREW_PREFIX/"lib/node_modules"
  #   node_modules.mkpath
  #   # Kill npm but preserve all other modules across node updates/upgrades.
  #   rm_r node_modules/"npm" if (node_modules/"npm").exist?

  #   cp_r libexec/"lib/node_modules/npm", node_modules
  #   # This symlink doesn't hop into homebrew_prefix/bin automatically so
  #   # we make our own. This is a small consequence of our
  #   # bottle-npm-and-retain-a-private-copy-in-libexec setup
  #   # All other installs **do** symlink to homebrew_prefix/bin correctly.
  #   # We ln rather than cp this because doing so mimics npm's normal install.
  #   ln_sf node_modules/"npm/bin/npm-cli.js", bin/"npm"
  #   ln_sf node_modules/"npm/bin/npx-cli.js", bin/"npx"
  #   ln_sf bin/"npm", HOMEBREW_PREFIX/"bin/npm"
  #   ln_sf bin/"npx", HOMEBREW_PREFIX/"bin/npx"

  #   (node_modules/"npm/npmrc").atomic_write("prefix = #{HOMEBREW_PREFIX}\n")
  # end

  test do
    (testpath/"test.js").write <<~EOS
      console.log("Hello from NodeJS")
    EOS
    Dir.mkdir(testpath/"typescript")
    (testpath/"typescript/typedfunc.ts").write <<~EOS
      'use strict';
      export function typed_sum(left: number, right: number): number {
        return left+right
      }
      export async function typed_sum_async(left: number, right: number): Promise<number> {
        return left+right
      }
      export function build_name(first: string, last = 'Smith') {
        return`${first} ${last}`
      }
      export function object_pattern_ts({asd}){
        return asd
      }
      export function typed_array(a: number[]): number{
        return a[0]+a[1]+a[2]
      }
      export function object_record(a: Record<string, number>): number {
        return a.element
      }
    EOS
    (testpath/"test_typescript.sh").write <<~EOS
      #!/usr/bin/env bash
      cd typescript
      echo 'load ts typedfunc.ts\ninspect\ncall typed_sum(4321, 50000)\nexit' | #{bin}/metacall
    EOS
    chmod("u+x", testpath/"test_typescript.sh")
    (testpath/"test.py").write <<~EOS
      print("Hello from Python")
    EOS
    (testpath/"test.rb").write <<~EOS
      print("Hello from Ruby")
    EOS
    (testpath/"test.java").write <<~EOS
      public class test {
        public static void main(String[]args) {
          System.err.println("Hello from Java");
        }
      }
    EOS

    # Tests
    assert_match "Hello from Python", shell_output("#{bin}/metacall test.py")
    assert_match "Hello from Ruby", shell_output("#{bin}/metacall test.rb")
    assert_match "Hello from NodeJS", shell_output("#{bin}/metacall test.js")
    assert_match "54321", shell_output(testpath/"test_typescript.sh")

    # TODO: Enable Java
    # assert_match "Hello from Java", shell_output("#{bin}/metacall test.java")
  end
end
