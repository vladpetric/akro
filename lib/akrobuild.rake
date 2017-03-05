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

$MODES = $MODE_COMPILE_FLAGS.keys
$COMPILER_PREFIX = $COMPILER_PREFIX.nil? ? "" : $COMPILER_PREFIX + " "
$LINKER_PREFIX = $LINKER_PREFIX.nil? ? $COMPILER_PREFIX : $LINKER_PREFIX + " "
$LINKER = $LINKER.nil? ? $COMPILER : $LINKER
$LINK_FLAGS = $LINK_FLAGS.nil? ? $COMPILE_FLAGS : $LINK_FLAGS
$MODE_LINK_FLAGS = $MODE_LINK_FLAGS.nil? ? $MODE_COMPILE_FLAGS : $MODE_LINK_FLAGS 

module Util
  def Util.make_relative_path(path)
    absolute_path = File.absolute_path(path)
    base_dir = File.absolute_path(Dir.pwd)
    base_dir << '/' if !base_dir.end_with?('/')
    r = absolute_path.start_with?(base_dir) ? absolute_path[base_dir.size..-1] : nil
    if !r.nil? && r.start_with?('/')
      raise "Relative path #{r} is not relative"
    end
    r
  end
end

module FileMapper
  # Extract build mode from path.
  # E.g., debug/a/b/c.o returns debug.
  def FileMapper.get_mode(path)
    rel_path = Util.make_relative_path(path)
    raise "Path #{path} does not belong to #{Dir.pwd}" if rel_path.nil?
    mode = rel_path[/^([^\/]*)/, 1]
    raise "Unknown mode #{mode} for #{path}" if !$MODES.include?(mode)
    mode
  end
  def FileMapper.get_mode_from_akpath(path)
    rel_path = Util.make_relative_path(path)
    raise "Path #{path} does not belong to #{Dir.pwd}" if rel_path.nil?
    mode = rel_path[/^\.akro\/([^\/]*)/, 1]
    raise "Unknown mode #{mode} for #{path}" if !$MODES.include?(mode)
    mode
  end
  # Strip the build mode from path.
  def FileMapper.strip_mode(path)
    rel_path = Util.make_relative_path(path)
    raise "Path #{path} does not belong to #{Dir.pwd}" if rel_path.nil?
    get_mode(rel_path) # for sanity checking
    rel_path[/^[^\/]*\/(.*)$/, 1]
  end
  # Maps object file to its corresponding depcache file.
  # E.g., release/a/b/c.o maps to .akro/release/a/b/c.depcache
  def FileMapper.map_obj_to_dc(path)
    FileMapper.get_mode(path)
    raise "#{path} is not a #{$OBJ_EXTENSION} file" if !path.end_with?($OBJ_EXTENSION)
    ".akro/#{path[0..-$OBJ_EXTENSION.length-1]}.depcache"
  end
  # Maps object file to its corresponding cpp file, if it exists.
  # E.g., release/a/b/c.o maps to a/b/c{.cpp,.cc,.cxx,.c++}
  def FileMapper.map_obj_to_cpp(path)
    raise "#{path} is not a #{$OBJ_EXTENSION} file" if !path.end_with?($OBJ_EXTENSION)
    file = FileMapper.strip_mode(path)
    file = file[0..-$OBJ_EXTENSION.length-1]
    # Under windows, make_relative_path also canonicalizes the path.
    srcs = $CPP_EXTENSIONS.map{|ext| file + ext}.select{|fname| File.exist?(fname)}.map{|fname| Util.make_relative_path(fname)}.uniq
    raise "Multiple sources for base name #{file}: #{srcs.join(' ')}" if srcs.length > 1
    srcs.length == 0? nil : srcs[0]
  end
  def FileMapper.map_cpp_to_dc(mode, path)
    $CPP_EXTENSIONS.map do |ext|
      return ".akro/#{mode}/#{path[0..-ext.length-1]}.depcache" if path.end_with?(ext)
    end
    raise "#{path} is not one of: #{$CPP_EXTENSIONS.join(',')}"
  end
  def FileMapper.map_cpp_to_obj(mode, path)
    $CPP_EXTENSIONS.map do |ext|
      return "#{mode}/#{path[0..-ext.length-1]}#{$OBJ_EXTENSION}" if path.end_with?(ext)
    end
    raise "#{path} is not one of: #{$CPP_EXTENSIONS.join(',')}"
  end
  # Maps depcache file to its corresponding cpp file, which should exist.
  # E.g., .akro/release/a/b/c.o maps to a/b/c{.cpp,.cc,.cxx,.c++}
  def FileMapper.map_dc_to_cpp(path)
    raise "#{path} is not a .depcache file" if !path.end_with?('.depcache') || !path.start_with?('.akro')
    file = path[/^\.akro\/(.*)\.depcache$/, 1]
    file = FileMapper.strip_mode(file)
    srcs = $CPP_EXTENSIONS.map{|ext| file + ext}.select{|fname| File.exist?(fname)}
    raise "Multiple sources for base name #{file}: #{srcs.join(' ')}" if srcs.length > 1
    raise "No sources for base name #{file}" if srcs.length == 0
    srcs[0]
  end
  def FileMapper.map_dc_to_compcmd(path)
    raise "#{path} is not a .depcache file" if !path.end_with?('.depcache') || !path.start_with?('.akro')
    path.gsub(/\.depcache$/, ".compcmd" )
  end
  def FileMapper.map_compcmd_to_cpp(path)
    raise "#{path} is not a .compcmd file" if !path.end_with?('.compcmd') || !path.start_with?('.akro')
    file = path[/^\.akro\/(.*)\.compcmd$/, 1]
    file = FileMapper.strip_mode(file)
    srcs = $CPP_EXTENSIONS.map{|ext| file + ext}.select{|fname| File.exist?(fname)}
    raise "Multiple sources for base name #{file}: #{srcs.join(' ')}" if srcs.length > 1
    raise "No sources for base name #{file}" if srcs.length == 0
    srcs[0]
  end
  def FileMapper.map_exe_to_linkcmd(path)
    ".akro/#{path.gsub(/\.exe$/, ".linkcmd" )}"
  end
  def FileMapper.map_linkcmd_to_exe(path)
    path[/^.akro\/(.*)\.linkcmd$/, 1] + ".exe"
  end
  def FileMapper.map_static_lib_to_linkcmd(path)
    ".akro/#{path.gsub(/#{$STATIC_LIB_EXTENSION}$/, ".stlinkcmd" )}"
  end
  def FileMapper.map_linkcmd_to_static_lib(path)
    path[/^.akro\/(.*)\.stlinkcmd$/, 1] + $STATIC_LIB_EXTENSION
  end
  def FileMapper.map_dynamic_lib_to_linkcmd(path)
    ".akro/#{path.gsub(/#{$DYNAMIC_LIB_EXTENSION}$/, ".dynlinkcmd" )}"
  end
  def FileMapper.map_linkcmd_to_dynamic_lib(path)
    path[/^.akro\/(.*)\.dynlinkcmd$/, 1] + $DYNAMIC_LIB_EXTENSION
  end
  # Maps header file to its corresponding cpp file, if it exists
  # E.g., a/b/c.h maps to a/b/c.cpp, if a/b/c.cpp exists, otherwise nil
  def FileMapper.map_header_to_cpp(path)
    rel_path = Util.make_relative_path(path)
    # file is not local
    return nil if rel_path.nil?
    srcs = $HEADER_EXTENSIONS.select{|ext| rel_path.end_with?(ext)}.collect{ |ext|
      base_path = rel_path[0..-ext.length-1]
      $CPP_EXTENSIONS.map{|cppext| base_path + cppext}.select{|file| File.exist?(file)}
    }.flatten.uniq
    raise "Multiple sources for base name #{path}: #{srcs.join(' ')}" if srcs.length > 1
    srcs.length == 0? nil : srcs[0]
  end
   
  def FileMapper.map_script_to_exe(path)
    path_no_ext = path[/^(.*)[^.\/]*$/, 1]
    srcs = $CPP_EXTENSIONS.map{|cppext| path + cppext}.select{|file| File.exist?(file)}
    srcs.length == 0? nil : path + ".exe"
  end
end

#Builder encapsulates the compilation/linking/dependecy checking functionality
module Builder
  def Builder.create_depcache(src, dc)
    success = false
    mode = FileMapper.get_mode_from_akpath(dc)
    basedir, _ = File.split(dc)
    FileUtils.mkdir_p(basedir)
    output = File.open(dc, "w")
    puts "Determining dependencies for #{dc}" if $VERBOSE_BUILD
    begin
      #Using backticks as Rake's sh outputs the command. Don't want that here.
      cmdline = CmdLine.dependency_cmdline(mode, src)
      puts cmdline if $VERBOSE_BUILD
      deps = `#{cmdline}`
      raise "Dependency determination failed for #{src}" if $?.to_i != 0
      # Replace quoted spaces with placeholders
      deps.gsub!(/\\ /, '<*%#?>') # a string that never exists in filenames
      # Get rid of endlines completeley
      deps.gsub!(/\\\n/, '')
      # also get rid of <filename>: at the beginning
      # split by spaces
      deps[/^[^:]*:(.*)$/, 1].split(' ').each do |line|
        # Output either a relative path if the file is local, or the original line.
        line.gsub!('<*%#?>', ' ')
        output << (Util.make_relative_path(line.strip) || line) << "\n"
      end
      output.close
      success = true
    ensure
      FileUtils.rm(dc) if !success
    end
  end

  def Builder.compile_object(src, obj)
    mode = FileMapper.get_mode(obj)
    basedir, _ = File.split(obj)
    FileUtils.mkdir_p(basedir)
    RakeFileUtils::sh(CmdLine.compile_cmdline(mode, src, obj)) do |ok, res|
      raise "Compilation failed for #{src}" if !ok
    end
  end

  def Builder.link_binary(objs, bin)
    mode = FileMapper.get_mode(bin)
    basedir, _ = File.split(bin)
    FileUtils.mkdir_p(basedir)
    RakeFileUtils::sh(CmdLine.link_cmdline(mode, objs, bin)) do |ok, res|
      raise "Linking failed for #{bin}" if !ok
    end
  end
  def Builder.archive_static_library(objs, bin)
    basedir, _ = File.split(bin)
    FileUtils.mkdir_p(basedir)
    RakeFileUtils::sh(CmdLine.static_lib_cmdline(objs, bin)) do |ok, res|
      raise "Archiving failed for #{bin}" if !ok
    end
  end

  def Builder.build_dynamic_library(mode, objs, additional_params, bin)
    mode = FileMapper.get_mode(bin)
    basedir, _ = File.split(bin)
    FileUtils.mkdir_p(basedir)
    RakeFileUtils::sh(CmdLine.dynamic_lib_cmdline(mode, objs, additional_params, bin)) do |ok, res|
      raise "Building dynamic library #{bin} failed" if !ok
    end
  end

  def Builder.depcache_object_collect(mode, top_level_srcs)
    all_covered_cpps = Set.new
    all_objects = []
    srcs = top_level_srcs
    while !srcs.empty?
      new_srcs = [] 
      dcs = srcs.map{|src| FileMapper.map_cpp_to_dc(mode, src)}
      dcs.each{|dc| Rake::Task[dc].invoke}
      dcs.each do |dc|
        cpp = FileMapper.map_dc_to_cpp(dc)
        obj = FileMapper.map_cpp_to_obj(mode, cpp)
        all_objects << obj if !all_objects.include?(obj)
        File.readlines(dc).map{|line| line.strip}.each do |header|
          new_cpp = FileMapper.map_header_to_cpp(header)
          if !new_cpp.nil? and !all_covered_cpps.include?(new_cpp)
            new_srcs << new_cpp
            all_covered_cpps << new_cpp
          end
        end
      end
      srcs = new_srcs
    end
    all_objects
  end
end

#Phony task that forces anything depending on it to run 
task "always"
  
rule ".compcmd" => ->(compcmd) {
  mode = FileMapper.get_mode_from_akpath(compcmd)
  src = FileMapper.map_compcmd_to_cpp(compcmd)
  cmd = CmdLine.compile_base_cmdline(mode, src)
  if File.exists?(compcmd) && File.read(compcmd).strip == cmd.strip then
    []
  else
    "always"
  end
} do |task|
  basedir, _ = File.split(task.name)
  FileUtils.mkdir_p(basedir)
  output = File.open(task.name, "w")
  mode = FileMapper.get_mode_from_akpath(task.name)
  src = FileMapper.map_compcmd_to_cpp(task.name)
  output << CmdLine.compile_base_cmdline(mode, src) << "\n"
  output.close
end

rule ".linkcmd" => ->(dc) {
  binary = FileMapper.map_linkcmd_to_exe(dc)
  raise "Internal error - linkcmd not mapped for #{binary}" if !$LINK_BINARY_OBJS.has_key?(binary)
  mode = FileMapper.get_mode_from_akpath(dc)
  cmd = CmdLine.link_cmdline(mode, $LINK_BINARY_OBJS[binary], binary)
  if File.exists?(dc) && File.read(dc).strip == cmd.strip then
    []
  else
    "always"
  end
} do |task|
  basedir, _ = File.split(task.name)
  binary = FileMapper.map_linkcmd_to_exe(task.name)
  FileUtils.mkdir_p(basedir)
  output = File.open(task.name, "w")
  mode = FileMapper.get_mode_from_akpath(task.name)
  output << CmdLine.link_cmdline(mode, $LINK_BINARY_OBJS[binary], binary) << "\n"
  output.close
end

rule ".dynlinkcmd" => ->(dc) {
  dynlib = FileMapper.map_linkcmd_to_dynamic_lib(dc)
  raise "Internal error - linkcmd not mapped for #{dynlib}" if !$LINK_BINARY_OBJS.has_key?(dynlib)
  mode = FileMapper.get_mode_from_akpath(dc)
  cmd = CmdLine.dynamic_lib_cmdline(mode, $LINK_BINARY_OBJS[dynlib], $LINK_LIBRARY_EXTRAFLAGS[dynlib], dynlib)
  if File.exists?(dc) && File.read(dc).strip == cmd.strip then
    []
  else
    "always"
  end
} do |task|
  basedir, _ = File.split(task.name)
  dynlib = FileMapper.map_linkcmd_to_dynamic_lib(task.name)
  FileUtils.mkdir_p(basedir)
  output = File.open(task.name, "w")
  mode = FileMapper.get_mode_from_akpath(task.name)
  output << CmdLine.dynamic_lib_cmdline(mode, $LINK_BINARY_OBJS[dynlib], $LINK_LIBRARY_EXTRAFLAGS[dynlib], dynlib) << "\n"
  output.close
end

rule ".stlinkcmd" => ->(dc) {
  stlib = FileMapper.map_linkcmd_to_static_lib(dc)
  raise "Internal error - linkcmd not mapped for #{stlib}" if !$LINK_BINARY_OBJS.has_key?(stlib)
  mode = FileMapper.get_mode_from_akpath(dc)
  cmd = CmdLine.static_lib_cmdline($LINK_BINARY_OBJS[stlib], stlib)
  if File.exists?(dc) && File.read(dc).strip == cmd.strip then
    []
  else
    "always"
  end
} do |task|
  basedir, _ = File.split(task.name)
  stlib = FileMapper.map_linkcmd_to_static_lib(task.name)
  FileUtils.mkdir_p(basedir)
  output = File.open(task.name, "w")
  mode = FileMapper.get_mode_from_akpath(task.name)
  output << CmdLine.static_lib_cmdline($LINK_BINARY_OBJS[stlib], stlib) << "\n"
  output.close
end


rule ".depcache" => ->(dc){
  [FileMapper.map_dc_to_compcmd(dc), FileMapper.map_dc_to_cpp(dc)] + 
  (File.exist?(dc) ? File.readlines(dc).map{|line| line.strip}.map{|file| File.exist?(file) ? file : "always"}: [])
} do |task|
  src = FileMapper.map_dc_to_cpp(task.name)
  Builder.create_depcache(src, task.name)
end

rule $OBJ_EXTENSION => ->(obj){
  src = FileMapper.map_obj_to_cpp(obj)
  raise "No source for object file #{obj}" if src.nil?
  dc = FileMapper.map_obj_to_dc(obj)
  [src, dc, FileMapper.map_dc_to_compcmd(dc)] +
  (File.exist?(dc) ? File.readlines(dc).map{|line| line.strip}: [])
} do |task|
  src = FileMapper.map_obj_to_cpp(task.name)
  Builder.compile_object(src, task.name)
end

def libname(mode, lib)
  "#{mode}/#{lib.path}#{if lib.static then $STATIC_LIB_EXTENSION else $DYNAMIC_LIB_EXTENSION end}"
end

$LINK_BINARY_OBJS = Hash.new
$LINK_LIBRARY_EXTRAFLAGS = Hash.new

rule ".exe" => ->(binary){
  obj = binary.gsub(/\.exe$/, $OBJ_EXTENSION)
  mode = FileMapper.get_mode(binary)
  cpp = FileMapper.map_obj_to_cpp(obj)
  raise "No proper #{$CPP_EXTENSIONS.join(',')} file found for #{binary}" if cpp.nil?
  Rake::Task["#{mode}/all_capturing_libs"].invoke
  obj_list = []
  # Two passes through the object list - the capturing libraries will
  # be inserted on the position of the *last* object in the list
  last_obj = Hash.new
  objs = Builder.depcache_object_collect(mode, [cpp])
  objs.each do |obj|
    if $LIB_CAPTURE_MAP.has_key?(obj)
      last_obj[$LIB_CAPTURE_MAP[obj]] = obj
    end
  end
  objs.each do |obj|
    if $LIB_CAPTURE_MAP.has_key?(obj)
      capture_lib = $LIB_CAPTURE_MAP[obj]
      if last_obj[capture_lib] == obj
        obj_list << capture_lib
      end
    else
      obj_list << obj
    end
  end
  $LINK_BINARY_OBJS[binary] = obj_list
  [FileMapper.map_exe_to_linkcmd(binary)] + obj_list
} do |task|
  Builder.link_binary(task.prerequisites[1..-1], task.name)
end

$MODES.each do |mode|
  rule /^#{mode}\/all_capturing_libs$/ => $AKRO_LIBS.select{|l| l.capture_deps}.collect{|l| libname(mode, l)} do |task|
    FileUtils.mkdir_p(mode)
    FileUtils::touch(task.name)
  end
end

rule $STATIC_LIB_EXTENSION => ->(library) {
  mode = FileMapper.get_mode(library)
  srcs = []
  lib = FileMapper.strip_mode(library)[0..-$STATIC_LIB_EXTENSION.length-1]
  libspec = nil
  $AKRO_LIBS.each do |alib|
    if alib.path == lib and alib.static
      raise "Library #{library} declared multiple times" if !libspec.nil?
      libspec = alib
      srcs << alib.sources
    end
  end
  raise "Library #{library} not found!" if libspec.nil?
  Rake::Task["#{mode}/all_capturing_libs"].invoke if !libspec.capture_deps
  srcs.flatten!
  if libspec.recurse
    objs = Builder.depcache_object_collect(mode, srcs)
  else
    objs = srcs.collect{|src| FileMapper.map_cpp_to_obj(mode, src)}
  end
  if libspec.capture_deps && !$CAPTURING_LIBS.include?(library)
    objs.each do |obj|
      if $LIB_CAPTURE_MAP.has_key?(obj)
        raise "Object #{obj} has dependency captures for multiple libraries - #{$LIB_CAPTURE_MAP[obj]} and #{library}"
      end
      $LIB_CAPTURE_MAP[obj] = library
    end
    $CAPTURING_LIBS << library
  end
  $LINK_BINARY_OBJS[library] = objs
  [FileMapper.map_static_lib_to_linkcmd(library)] + objs
} do |task|
  Builder.archive_static_library(task.prerequisites[1..-1], task.name)
end

rule $DYNAMIC_LIB_EXTENSION => ->(library) {
  mode = FileMapper.get_mode(library)
  srcs = []
  lib = FileMapper.strip_mode(library)[0..-$DYNAMIC_LIB_EXTENSION.length-1]
  libspec = nil
  $AKRO_LIBS.each do |alib|
    if alib.path == lib and not alib.static
      raise "Library #{library} declared multiple times" if !libspec.nil?
      libspec = alib
      srcs << alib.sources
    end
  end
  raise "Library #{library} not found!" if libspec.nil?
  Rake::Task["#{mode}/all_capturing_libs"].invoke if !libspec.capture_deps

  srcs.flatten!
  if libspec.recurse
    objs = Builder.depcache_object_collect(mode, srcs)
  else
    objs = srcs.collect{|src| FileMapper.map_cpp_to_obj(mode, src)}
  end
  if libspec.capture_deps && !$CAPTURING_LIBS.include?(library)
    objs.each do |obj|
      if $LIB_CAPTURE_MAP.has_key?(obj)
        raise "Object #{obj} has dependency captures for multiple libraries - #{$LIB_CAPTURE_MAP[obj]} and #{library}"
      end
      $LIB_CAPTURE_MAP[obj] = library
    end
    $CAPTURING_LIBS << library
  end
  $LINK_BINARY_OBJS[library] = objs
  $LINK_LIBRARY_EXTRAFLAGS[library] = libspec.additional_params
  [FileMapper.map_dynamic_lib_to_linkcmd(library)] + objs
} do |task|
  libspec = nil
  lib = FileMapper.strip_mode(task.name)[0..-$DYNAMIC_LIB_EXTENSION.length-1]
  $AKRO_LIBS.each do |alib|
    if alib.path == lib and not alib.static
      libspec = alib
    end
  end
  mode = FileMapper.get_mode(task.name)
  Builder.build_dynamic_library(mode, task.prerequisites[1..-1], libspec.additional_params, task.name)
end

task :clean do
  FileUtils::rm_rf(".akro/")
  $MODES.each{|mode| FileUtils::rm_rf("#{mode}/")}
end

$MODES.each do |mode|
  task mode
  task "test_#{mode}"
  $AKRO_BINARIES.each do |bin|
    raise "Binary cannot start with mode #{bin}" if bin.start_with?(mode + "/")
    Rake::Task[mode].enhance(["#{mode}/#{bin}"])
  end
  # Build all non-capturing libs by default.
  # Capturing libs are automatically invoked by binaries anyway.
  Rake::Task[mode].enhance($AKRO_LIBS.select{|l| !l.capture_deps}.map{|l| libname(mode, l)})
  $AKRO_TESTS.each do |test|
    test_dep = 
      if !test.binary.nil?
        "#{mode}/#{test.binary}"
      else
        # map_script_to_exe may return nil, which is fine
        FileMapper.map_script_to_exe(test.script)
      end
    task "#{test.name}_test_#{mode}" => test_dep do |task|
      puts "Running test #{task.name}"
      base = (if !test.script.nil? then "#{test.script}" else "#{mode}/#{test.binary}" end)
      params = (if !test.cmdline.nil? then " " + test.cmdline else "" end)
      new_ld_path = if ENV.has_key?("LD_LIBRARY_PATH") then "#{mode}/:#{ENV['LD_LIBRARY_PATH']}" else "#{mode}/" end
      raise "Test #{task.name} failed" if !silent_exec(base + params, verbose: $VERBOSE_BUILD, env: {"MODE" => mode, "LD_LIBRARY_PATH" => new_ld_path})
      puts "Test #{task.name} passed"
    end
    Rake::Task["test_#{mode}"].enhance(["#{test.name}_test_#{mode}"])
  end
end
