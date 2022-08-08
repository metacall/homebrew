class Metacall < Formula
  desc "Ultimate polyglot programming experience"
  homepage "https://metacall.io/"
  version "0.5.24"
  url "https://github.com/metacall/core/archive/refs/tags/v#{version}.tar.gz"
  # checksum for 0.5.24
  sha256 "a029fcaa847e4ea1359227d0cc97577971b1f59a421ec10faa83881e655f2a8d"
  license "Apache-2.0"
  head "https://github.com/metacall/core", branch: "develop"

  depends_on "cmake" => :build
  depends_on "node@14"
  depends_on "openjdk"
  depends_on "python@3.9"
  depends_on "ruby@3.1"
  uses_from_macos "ruby@3.1"

  def install
    Dir.mkdir("build")
    Dir.chdir("build")
    args = std_cmake_args + %W[
      -Wno-dev
      -DCMAKE_BUILD_TYPE=Release
      -DOPTION_BUILD_SECURITY=OFF
      -DOPTION_FORK_SAFE=OFF
      -DOPTION_BUILD_SCRIPTS=OFF
      -DOPTION_BUILD_TESTS=OFF
      -DOPTION_BUILD_EXAMPLES=OFF
      -DOPTION_BUILD_LOADERS_PY=ON
      -DOPTION_BUILD_LOADERS_NODE=ON
      -DNodeJS_INSTALL_PREFIX=/usr/local/Cellar/metacall/#{version}
      -DOPTION_BUILD_LOADERS_JAVA=ON
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
    ]
    system "cmake", *args, ".."
    system "cmake", "--build", ".", "--target", "install"

    shebang = "\#!/usr/bin/env bash\n"
    # debug = "set -euxo pipefail\n"

    metacall_extra = [
      "LOC=/usr/local/Cellar/metacall/#{version}\n",
      "export LOADER_LIBRARY=\"$LOC/lib\"\n",
      "export SERIAL_LIBRARY_PATH=\"$LOC/lib\"\n",
      "export DETOUR_LIBRARY_PATH=\"$LOC/lib\"\n",
      "export PORT_LIBRARY_PATH=\"$LOC/lib\"\n",
      "export CONFIGURATION_PATH=\"$LOC/configurations/global.json\"\n",
    ]
    cmds = [shebang, *metacall_extra]
    cmds.append("export LOADER_SCRIPT_PATH=\"\${LOADER_SCRIPT_PATH:-\`pwd\`}\"\n")
    cmds.append("$LOC/metacallcli.app/Contents/MacOS/metacallcli $@\n")

    File.open("metacall.sh", "w") do |f|
      f.write(*cmds)
    end

    chmod("u+x", "metacall.sh")
    bin.install "metacall.sh" => "metacall"
  end

  test do
    (testpath/"test.js").write("console.log(\"Hello from NodeJS\")\n")
    # TypeScript special test
    Dir.mkdir(testpath/"typescript")
    (testpath/"typescript/typedfunc.ts").write("'use strict';export function typed_sum(left:number,right:number):number{return left+right}export async function typed_sum_async(left:number,right:number):Promise<number>{return left+right}export function build_name(first:string,last='Smith'){return`${first} ${last}`}export function object_pattern_ts({asd}){return asd}export function typed_array(a:number[]):number{return a[0]+a[1]+a[2]}export function object_record(a:Record<string, number>):number{return a.element}")

    (testpath/"test.py").write("print(\"Hello from Python\")\n")
    (testpath/"test.rb").write("print(\"Hello from Ruby\")\n")
    (testpath/"test.java").write('public class HelloWorld{public static void main(String[]args)' \
                                 '{System.err.println("Hello from Java!");System.out.println("Hello from Java!");' \
                                 'System.out.println("Hello from Java!");System.out.println("Hello from Java!");}}')
    # Tests
    assert_match "Hello from Python", shell_output("#{bin}/metacall test.py")
    assert_match "Hello from Ruby", shell_output("#{bin}/metacall test.rb")
    assert_match "Script (test.java) loaded correctly\n", shell_output("#{bin}/metacall test.java")
    assert_match "Hello from NodeJS", shell_output("#{bin}/metacall test.js")
    assert_match "9.0", shell_output("cd typescript && echo 'load ts typedfunc.ts\ninspect\ncall typed_sum(4, 5)\nexit' | #{bin}/metacall")
  end
end
