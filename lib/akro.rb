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
require 'tempfile'

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
$CAPTURING_LIBS = Set.new

AkroTest = Struct.new("AkroTest", :name, :script, :binary, :cmdline)
$AKRO_TESTS = []
$AKRO_TESTS_MAP = Hash.new
def add_test(name: nil, script: nil, binary: nil, cmdline: nil)
  raise "Test must have a name" if name.nil?
  raise "Test must have at least a script and a binary" if script.nil? and binary.nil?
  raise "Binary must end in .exe" if !binary.nil? and !binary.end_with?(".exe")
  test = AkroTest.new(name, script, binary, cmdline)
  $AKRO_TESTS << test
  raise "Test #{name} appears multiple times" if $AKRO_TESTS_MAP.has_key?(name)
  $AKRO_TESTS_MAP[name] = test
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

AkroLibrary = Struct.new("AkroLibrary", :path, :sources, :static, :recurse, :capture_deps, :additional_params)
$AKRO_LIBS = []

def add_static_library(path: nil, sources: nil, recurse: true, capture_deps: true, additional_params: nil)
  raise "Must specify path for static library" if path.nil?
  raise "Must specify source for static library #{path}" if sources.nil?
  $AKRO_LIBS << AkroLibrary.new(path, sources, true, recurse, capture_deps, additional_params)
end
def add_dynamic_library(path: nil, sources: nil, recurse: true, capture_deps: true, additional_params: nil)
  raise "Must specify path for dynamic library" if path.nil?
  raise "Must specify source for dynamic library #{path}" if sources.nil?
  $AKRO_LIBS << AkroLibrary.new(path, sources, false, recurse, capture_deps, additional_params)
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

# Module with overrideable command line functions
module CmdLine
  def CmdLine.compile_base_cmdline(mode)
    "#{$COMPILER_PREFIX}#{$COMPILER} #{$COMPILE_FLAGS} #{$MODE_COMPILE_FLAGS[mode]}"
  end
  def CmdLine.dependency_cmdline(mode, src)
    "#{CmdLine.compile_base_cmdline(mode)} -M #{src}"
  end
  def CmdLine.compile_cmdline(mode, src, obj)
    "#{CmdLine.compile_base_cmdline(mode)} -c #{src} -o #{obj}"
  end
  def CmdLine.link_cmdline(mode, objs, bin)
    "#{$LINKER_PREFIX}#{$LINKER} #{$LINK_FLAGS} #{$MODE_LINK_FLAGS[mode]} #{objs.join(' ')} #{$ADDITIONAL_LINK_FLAGS} -o #{bin}"
  end
  def CmdLine.static_lib_cmdline(objs, bin)
    "#{$AR} rcs #{bin} #{objs.join(' ')}"
  end
  def CmdLine.dynamic_lib_cmdline(mode, objs, additional_params, bin)
    if !additional_params.nil?
      if additional_params.kind_of?(Array)
        extra_params = " " + objs.join(" ")
      elsif additional_params.respond_to?(:to_str)
        extra_params = " " + additional_params.to_str
      else
        raise "Additional params to a dynamic library must be either a string or an array of strings"
      end
    else
      extra_params = ""
    end
    soname = if bin.include?("/") then FileMapper.strip_mode(bin) else bin end
    "#{$LINKER_PREFIX}#{$COMPILER} -shared #{$COMPILE_FLAGS} #{$MODE_COMPILE_FLAGS[mode]} -Wl,-soname,#{soname} -o #{bin} #{objs.join(' ')}#{extra_params}"
  end
end

# Execute command, redirect output to temporary file, and print if error
def silent_exec(command, verbose: false, lines_if_error: 200, env: {})
  Tempfile.open('testout') do |output|
    puts command if verbose
    if !system(env, command, [:out, :err] => output)
      output.close(unlink_now=false)
      if env.empty?()
        puts "Command <#{command}> failed:"
      else
        envstr = env.map{|k,v| "#{k}=#{v}"}.join(' ')
        puts "Command <#{envstr} #{command}> failed:"
      end
      lines = IO.readlines(output.path)
      lines = lines[-lines_if_error..-1] if lines.size() > lines_if_error
      puts lines
      return false
    end
  end
  return true
end

def akro_multitask
  Rake.application.options.enable_multitask = true
end