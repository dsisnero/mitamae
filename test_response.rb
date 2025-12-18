#!/usr/bin/env ruby
require 'tempfile'

# Mock build object
class MockBuild
  def filename(path)
    path.is_a?(Array) ? path.map { |p| "filename(#{p})" } : "filename(#{path})"
  end
end

# Mock command class
class MockCommand
  attr_accessor :build

  def initialize(build)
    @build = build
  end
end

class MockMrbc < MockCommand
  attr_accessor :compile_options

  def initialize(build)
    super
    @command = nil
    @compile_options = '-B%<funcname>s -o-'
  end

  def run(_out, infiles, funcname, cdump = true)
    @command ||= 'mrbc'
    infiles = [infiles].flatten

    puts "MRBC PATCHED: Processing #{infiles.size} files"
    puts "MRBC: First file: #{build.filename(infiles.first)}" if infiles.size > 0
    response_file = nil
    if infiles.size > 100
      puts "MRBC: Creating response file for #{infiles.size} files (Windows command line limit workaround)"
      response_file = Tempfile.new(['mrbc', '.rsp'])
      infiles.each { |path| response_file.puts build.filename(path) }
      response_file.close
      puts "MRBC: Response file created at #{response_file.path}"
      infiles = ["@#{response_file.path}"]
      puts "MRBC: New infiles = #{infiles.inspect}"
    else
      puts "MRBC: Not using response file (file count = #{infiles.size})"
    end

    begin
      infiles.each_with_index do |f, i|
        puts "MRBC: #{f}" if i == 0
      end
      cmd = %("#{build.filename @command}" #{'-S' if cdump} #{format(@compile_options,
                                                                     funcname: funcname)} #{build.filename(infiles).map do |f|
                                                                                            %("#{f}")
                                                                                          end.join(' ')})
      puts "MRBC: Command length: #{cmd.length}"
      puts "MRBC: Command: #{cmd}"
      # simulate IO.popen
      puts 'MRBC: Would execute command'
      # if success
    ensure
      response_file&.close!
    end
  end
end

build = MockBuild.new
mrbc = MockMrbc.new(build)

# Test with 200 dummy files
infiles = (1..200).map { |i| "path/to/file#{i}.rb" }
puts 'Testing with 200 files...'
mrbc.run($stdout, infiles, 'test_func', true)

# Test with 50 files
infiles2 = (1..50).map { |i| "path/to/file#{i}.rb" }
puts "\nTesting with 50 files..."
mrbc.run($stdout, infiles2, 'test_func', true)
