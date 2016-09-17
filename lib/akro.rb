# Copyright (c) 2016 Vlad Petric

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

require 'rake'

$VERBOSE_BUILD = false

# Use $COMPILER_PREFIX for things like ccache
$COMPILER_PREFIX = nil
$COMPILER = "g++"
$COMPILE_FLAGS = "-Wall"
$MODE_COMPILE_FLAGS = {
  "debug" => "-g3",
  "release" => "-O3 -g3"
}

$AR = "ar"

# nil for linker means - use the same as the compiler
$LINKER = nil
$LINKER_PREFIX = nil
$LINK_FLAGS = nil
$MODE_LINK_FLAGS = nil
# $ADDITIONAL_LINK_FLAGS is for third party libraries and objects
$ADDITIONAL_LINK_FLAGS = ""

$HEADER_EXTENSIONS = [".h", ".hpp", ".H"]
$CPP_EXTENSIONS = [".c", ".cc", ".cpp", ".cxx", ".c++", ".C"]
$OBJ_EXTENSION = ".o"
$STATIC_LIB_EXTENSION = ".a"
$DYNAMIC_LIB_EXTENSION = ".so"

$LIB_CAPTURE_MAP = Hash.new

AkroTest = Struct.new("AkroTest", :name, :script, :binary, :cmdline)
$AKRO_TESTS = []
def add_test(name: nil, script: nil, binary: nil, cmdline: nil)
  $AKRO_TESTS << AkroTest.new(name, script, binary, cmdline)
end

$AKRO_BINARIES = []
def add_binary(path)
  $AKRO_BINARIES << path.to_str()
end

def add_binaries(*paths)
  paths.each do |path|
    $AKRO_BINARIES << path.to_str()
  end
end

AkroLibrary = Struct.new("AkroLibrary", :path, :sources, :static, :recurse, :capture_deps)
$AKRO_LIBS = []

def add_library(path: nil, sources: nil, static: true, recurse: true, capture_deps: true)
  raise "Must specify path for library" if path.nil?
  raise "Must specify source for library #{path}" if sources.nil?
  $AKRO_LIBS << AkroLibrary.new(path, sources, static, recurse, capture_deps)
end

def add_tests(*tests)
  tests.each do |t|
    if t.respond_to?(:to_str)
      s = t.to_str()
      add_test(name: s, script: s, binary: s, cmdline: nil)
    elsif t.is_a?(AkroTest)
      $AKRO_TESTS << t
    else
      raise "Can't add test of class #{t.class.name} "
    end
  end
end
