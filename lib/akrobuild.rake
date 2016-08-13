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
# All rights reserved
# This file is distributed subject to GNU GPL version 3. See the files
# GPLv3.txt and License.txt in the instructions subdirectory for details.

# Akro build is a C++ build system with automated dependency tracking.
# See the README file for a detailed description.
#
# Akro build is inspired by Maxim Trokhimtchouk's autobuild
# https://github.com/petver29/autobuild
#
# Although it borrows many ideas from autobuild, it is a from-scratch, clean-room
# implementation.

$AKRO_VERBOSE = $VERBOSE_BUILD.nil? ? false : $VERBOSE_BUILD
$AKRO_COMPILER_PREFIX = $COMPILER_PREFIX.nil? ? "" : $COMPILER_PREFIX + " "
$AKRO_COMPILER = $COMPILER.nil? ? "g++" : $COMPILER
$AKRO_COMPILE_FLAGS = $COMPILE_FLAGS.nil? ? "-Wall" : $COMPILE_FLAGS
$AKRO_MODE_COMPILE_FLAGS = $MODE_COMPILE_FLAGS.nil? ? {
  "debug" => "-g3",
  "release" => "-O3 -g3"
} : $MODE_COMPILE_FLAGS

$MODES = $AKRO_MODE_COMPILE_FLAGS.keys

$AKRO_LINKER_PREFIX = $LINKER_PREFIX.nil? ? $AKRO_COMPILER_PREFIX : $LINKER_PREFIX + " "
$AKRO_LINKER = $LINKER.nil? ? $AKRO_COMPILER : $LINKER
$AKRO_LINK_FLAGS = $LINK_FLAGS.nil? ? $AKRO_COMPILE_FLAGS : $LINK_FLAGS
$AKRO_MODE_LINK_FLAGS = $MODE_LINK_FLAGS.nil? ? $AKRO_MODE_COMPILE_FLAGS : $MODE_LINK_FLAGS 
$AKRO_ADDITIONAL_LINK_FLAGS = $ADDITIONAL_LINK_FLAGS.nil? ? "" : $ADDITIONAL_LINK_FLAGS

$HEADER_EXTENSIONS = [".h", ".hpp"]
$CPP_EXTENSIONS = [".c", ".cc", ".cpp", ".cxx", ".c++"]
$OBJ_EXTENSION = ".o"

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
  def FileMapper.get_mode_from_dc(path)
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
    srcs = $CPP_EXTENSIONS.map{|ext| file + ext}.select{|fname| File.exist?(fname)}
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
  def FileMapper.map_exe_to_linkcmd(path)
    ".akro/#{path.gsub(/\.exe$/, ".linkcmd" )}"
  end
  # Maps header file to its corresponding cpp file, if it exists
  # E.g., a/b/c.h maps to a/b/c.cpp, if a/b/c.cpp exists, otherwise nil
  def FileMapper.map_header_to_cpp(path)
    rel_path = Util.make_relative_path(path)
    # file is not local
    return nil if rel_path.nil?
    #$HEADER_EXTENSIONS.select{|ext| rel_path.end_with?(ext)}.each do |ext|
    #end
    srcs = $HEADER_EXTENSIONS.select{|ext| rel_path.end_with?(ext)}.collect{ |ext|
      base_path = rel_path[0..-ext.length-1]
      $CPP_EXTENSIONS.map{|cppext| base_path + cppext}.select{|file| File.exist?(file)}
    }.flatten.uniq
    raise "Multiple sources for base name #{path}: #{srcs.join(' ')}" if srcs.length > 1
    srcs.length == 0? nil : srcs[0]
  end
end

#Builder encapsulates the compilation/linking/dependecy checking functionality
module Builder
  def Builder.compile_base_cmdline(mode)
    "#{$AKRO_COMPILER_PREFIX}#{$AKRO_COMPILER} #{$AKRO_COMPILE_FLAGS} #{$AKRO_MODE_COMPILE_FLAGS[mode]}"
  end
  def Builder.dependency_cmdline(mode, src)
    "#{Builder.compile_base_cmdline(mode)} -M #{src}"
  end
  def Builder.compile_cmdline(mode, src, obj)
    "#{Builder.compile_base_cmdline(mode)} -c #{src} -o #{obj}"
  end
  def Builder.link_cmdline_placeholder(mode)
    "#{$AKRO_LINKER_PREFIX}#{$AKRO_LINKER} #{$AKRO_LINK_FLAGS} #{$AKRO_MODE_LINK_FLAGS[mode]} <placeholder for objs> #{$AKRO_ADDITIONAL_LINK_FLAGS} -o <placeholder for binary>"
  end
  def Builder.link_cmdline(mode, objs, bin)
    "#{$AKRO_LINKER_PREFIX}#{$AKRO_LINKER} #{$AKRO_LINK_FLAGS} #{$AKRO_MODE_LINK_FLAGS[mode]} #{objs.join(' ')} #{$AKRO_ADDITIONAL_LINK_FLAGS} -o #{bin}"
  end
  def Builder.create_depcache(src, dc)
    success = false
    mode = FileMapper.get_mode_from_dc(dc)
    basedir, _ = File.split(dc)
    FileUtils.mkdir_p(basedir)
    output = File.open(dc, "w")
    puts "Determining dependencies for #{dc}" if $AKRO_VERBOSE
    begin
      #Using backticks as Rake's sh outputs the command. Don't want that here.
      cmdline = Builder.dependency_cmdline(mode, src)
      puts cmdline if $AKRO_VERBOSE
      deps = `#{cmdline}`
      raise "Dependency determination failed for #{src}" if $?.to_i != 0
      # NOTE(vlad): spaces within included filenames are not supported
      # Get rid of \ at the end of lines, and also of the newline
      deps.gsub!(/\\\n/, '')
      # also get rid of <filename>: at the beginning
      deps[/^[^:]*:(.*)$/, 1].split(' ').each do |line|
        # Output either a relative path if the file is local, or the original line.
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
    RakeFileUtils::sh(Builder.compile_cmdline(mode, src, obj)) do |ok, res|
      raise "Compilation failed for #{src}" if !ok
    end
  end

  def Builder.link_binary(objs, bin)
    mode = FileMapper.get_mode(bin)
    basedir, _ = File.split(bin)
    FileUtils.mkdir_p(basedir)
    RakeFileUtils::sh(Builder.link_cmdline(mode, objs, bin)) do |ok, res|
      raise "Linking failed for #{bin}" if !ok
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
        all_objects << obj
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
  
rule ".compcmd" => ->(dc) {
  mode = FileMapper.get_mode_from_dc(dc)
  cmd = Builder.compile_base_cmdline(mode)
  if File.exists?(dc) && File.read(dc).strip == cmd then
    []
  else
    "always"
  end
} do |task|
  basedir, _ = File.split(task.name)
  FileUtils.mkdir_p(basedir)
  output = File.open(task.name, "w")
  mode = FileMapper.get_mode_from_dc(task.name)
  output << Builder.compile_base_cmdline(mode) << "\n"
  output.close
end

rule ".linkcmd" => ->(dc) {
  mode = FileMapper.get_mode_from_dc(dc)
  cmd = Builder.link_cmdline_placeholder(mode)
  if File.exists?(dc) && File.read(dc).strip == cmd then
    []
  else
    "always"
  end
} do |task|
  basedir, _ = File.split(task.name)
  FileUtils.mkdir_p(basedir)
  output = File.open(task.name, "w")
  mode = FileMapper.get_mode_from_dc(task.name)
  output << Builder.link_cmdline_placeholder(mode) << "\n"
  output.close
end

rule ".depcache" => ->(dc){
  [FileMapper.map_dc_to_compcmd(dc), FileMapper.map_dc_to_cpp(dc)] + 
  (File.exist?(dc) ? File.readlines(dc).map{|line| line.strip}: [])
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

rule ".exe" => ->(binary){
  obj = binary.gsub(/\.exe$/, $OBJ_EXTENSION)
  mode = FileMapper.get_mode(binary)
  cpp = FileMapper.map_obj_to_cpp(obj)
  raise "No proper #{$CPP_EXTENSIONS.join(',')} file found for #{binary}" if cpp.nil?
  [FileMapper.map_exe_to_linkcmd(binary)] + Builder.depcache_object_collect(mode, [cpp])
} do |task|
  Builder.link_binary(task.prerequisites[1..-1], task.name)
end

task :clean do
  FileUtils::rm_rf(".akro/")
  $MODES.each{|mode| FileUtils::rm_rf("#{mode}/")}
end
