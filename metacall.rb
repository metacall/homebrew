# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class Metacall < Formula
  desc "MetaCall: The ultimate polyglot programming experience"
  homepage "https://metacall.io/"
  version "0.5.24"
  url "https://github.com/metacall/core/archive/refs/tags/v#{version}.zip"
  head "https://github.com/metacall/core", branch: "master"
  license "Apache-2.0"
  # checksum for 0.5.24
  sha256 "04d9f1758dab409e1b1aeb279f78dca2b3b02fb1f59d8574d2457eee04b16f3e"

  depends_on "cmake" => :build
  depends_on "python@3.9"
  depends_on "node@14"
  depends_on "ruby@3.1" 
  depends_on "java"

  
  def install
    # ENV.deparallelize  # if your formula fails when building in parallel
    # Remove unrecognized options if warned by configure
    # https://rubydoc.brew.sh/Formula.html#std_configure_args-instance_method
    # system "./configure", *std_configure_args, "--disable-silent-rules"
    system "mkdir build"
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
      -DOPTION_BUILD_LOADERS_NODE=OFF
      -DNodeJS_INSTALL_PREFIX=/usr/local/Cellar/metacall/#{version}
      -DOPTION_BUILD_LOADERS_JAVA=ON
      -DOPTION_BUILD_LOADERS_JS=OFF
      -DOPTION_BUILD_LOADERS_C=OFF
      -DOPTION_BUILD_LOADERS_COB=OFF
      -DOPTION_BUILD_LOADERS_CS=OFF
      -DOPTION_BUILD_LOADERS_RB=ON
      -DOPTION_BUILD_LOADERS_TS=OFF
      -DOPTION_BUILD_LOADERS_FILE=ON
      -DOPTION_BUILD_PORTS=ON
      -DOPTION_BUILD_PORTS_PY=ON
      -DOPTION_BUILD_PORTS_NODE=OFF
    ]
    system "cmake", *args, ".."
    system "cmake", "--build", "." , "--target", "install"

    shebang = "\#!/usr/bin/env bash\n"

    metacall_extra = %W[
      LOC=/usr/local/Cellar/metacall/#{version}\n
      LOADER_LIBRARY="$LOC/lib"\n
      SERIAL_LIBRARY_PATH="$LOC/lib"\n
      DETOUR_LIBRARY_PATH="$LOC/lib"\n
      PORT_LIBRARY_PATH="$LOC/lib"\n
      CONFIGURATION_PATH=$LOC/configurations/global.json\n
    ]
    cmds = [shebang, *metacall_extra]
    cmds.append("[[ -n $LOADER_SCRIPT_PATH ]] && LOADER_SCRIPT_PATH=\"$CWD\"\n")
    cmds.append("$LOC/metacallcli.app/Contents/MacOS/metacallcli $@\n")

    begin 
      file = File.open("metacall.sh", "w") 
      file.write(*cmds)
    rescue IOError => e
      system "false" # fails/raise exception
    ensure
      file.close unless file.nil?
    end
    #system "echo" ,"-n", "\#!/usr/bin/env bash >> metacall.sh"
    #system "echo" ,"-n", "LOC=/usr/local/Cellar/metacall/#{version} >> metacall.sh"
    ##system "echo" ,"-n", "#CORE_ROOT=$LOC/runtimes/dotnet/shared/Microsoft.NETCore.App/ # TODO: Add DotNet support"
    #system "echo" ,"-n", "LOADER_LIBRARY=\"$LOC/lib\" >> metacall.sh"
    #system "echo" ,"-n", "SERIAL_LIBRARY_PATH=\"$LOC/lib\" >> metacall.sh"
    #system "echo" ,"-n", "DETOUR_LIBRARY_PATH=\"$LOC/lib\" >> metacall.sh"
    #system "echo" ,"-n", "PORT_LIBRARY_PATH=\"$LOC/lib\" >> metacall.sh"
    #system "echo" ,"-n", "[[ -n $LOADER_SCRIPT_PATH ]] && LOADER_SCRIPT_PATH=\"$CWD\" >> metacall.sh"
    #system "echo" ,"-n", "CONFIGURATION_PATH=$LOC/configurations/global.json >> metacall.sh"
    #system "echo" ,"-n", "$LOC/metacallcli.app/Contents/MacOS/metacallcli $@ >> metacall.sh"
    system "chmod", "u+x", "metacall.sh"
    bin.install "metacall.sh" => "metacall"
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test metacall`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    # Creating tests files
    system "echo", "-n", "console.log('Hello from NodeJS') >> testJS.js"
    system "echo", "-n", "print('Hello from Python) >> testPy.py"
    system "echo", "-n", "print('Hello from Ruby) >> testRuby.rb"
    # Tests
    system "/usr/local/Cellar/metacall/#{version}/metacallcli.app/Contents/MacOS/metacallcli", "testJS.js", "|", "grep -i 'Hello from NodeJS'"
    system "/usr/local/Cellar/metacall/#{version}/metacallcli.app/Contents/MacOS/metacallcli", "testPy.py", "|", "grep -i 'Hello from Python'"
    system "/usr/local/Cellar/metacall/#{version}/metacallcli.app/Contents/MacOS/metacallcli", "testRuby.rb", "|", "grep -i 'Hello from Ruby'"
  end
end
