class Metacall < Formula
  desc "Ultimate polyglot programming experience"
  homepage "https://metacall.io/"
  url "https://github.com/metacall/core/archive/refs/tags/v#{version}.tar.gz"
  version "0.5.24"
  # checksum for 0.5.24
  sha256 "04d9f1758dab409e1b1aeb279f78dca2b3b02fb1f59d8574d2457eee04b16f3e"
  license "Apache-2.0"
  head "https://github.com/metacall/core", branch: "master"

  depends_on "cmake" => :build
  depends_on "node@14"
  depends_on "openjdk"
  depends_on "python@3.9"
  depends_on "ruby@3.1" 

  
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
    system "cmake", "--build", ".", "--target", "install"

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
      file&.close
    end
    chmod("u+x", "metacall.sh")
    bin.install "metacall.sh" => "metacall"
  end

  test do
    system "echo", "-n", "console.log('Hello from NodeJS') >> testJS.js"
    system "echo", "-n", "print('Hello from Python) >> testPy.py"
    system "echo", "-n", "print('Hello from Ruby) >> testRuby.rb"
    # Tests
    system "/usr/local/Cellar/metacall/#{version}/metacallcli.app/Contents/MacOS/metacallcli", "testJS.js", "|", "grep -i 'Hello from NodeJS'"
    system "/usr/local/Cellar/metacall/#{version}/metacallcli.app/Contents/MacOS/metacallcli", "testPy.py", "|", "grep -i 'Hello from Python'"
    system "/usr/local/Cellar/metacall/#{version}/metacallcli.app/Contents/MacOS/metacallcli", "testRuby.rb", "|", "grep -i 'Hello from Ruby'"
  end
end
