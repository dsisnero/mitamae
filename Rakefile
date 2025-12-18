# frozen_string_literal: true

require 'fileutils'
require 'shellwords'

MRUBY_VERSION = '3.0.0'

MRUBY_BUILD_PATCH = <<~'PATCH'
  --- mruby/lib/mruby/build.rb  2021-03-05 00:07:35.000000000 -0800
  +++ mruby/lib/mruby/build.rb  2021-03-05 12:25:15.159190950 -0800
  @@ -320,12 +320,16 @@
         return @mrbcfile if @mrbcfile

         gem_name = "mruby-bin-mrbc"
  -      gem = @gems[gem_name]
  -      gem ||= (host = MRuby.targets["host"]) && host.gems[gem_name]
  -      unless gem
  -        fail "external mrbc or mruby-bin-mrbc gem in current('#{@name}') or 'host' build is required"
  +      if (gem = @gems[gem_name])
  +        @mrbcfile = exefile("#{gem.build.build_dir}/bin/mrbc")
  +      elsif !host? && (host = MRuby.targets["host"])
  +        if (gem = host.gems[gem_name])
  +          @mrbcfile = exefile("#{gem.build.build_dir}/bin/mrbc")
  +        elsif host.mrbcfile_external?
  +          @mrbcfile = host.mrbcfile
  +        end
         end
  -      @mrbcfile = exefile("#{gem.build.build_dir}/bin/mrbc")
  +      @mrbcfile || fail("external mrbc or mruby-bin-mrbc gem in current('#{@name}') or 'host' build is required")
       end

       def mrbcfile=(path)
PATCH

MRUBY_COMMAND_PATCH = <<~'PATCH'
  --- mruby/lib/mruby/build/command.rb	2025-12-18 14:35:59
  +++ mruby/lib/mruby/build/command.rb	2025-12-18 14:36:07
  @@ -333,18 +333,38 @@
       def run(out, infiles, funcname, cdump = true)
         @command ||= @build.mrbcfile
         infiles = [infiles].flatten
  -      infiles.each_with_index do |f, i|
  -        _pp i == 0 ? "MRBC" : "", f.relative_path, indent: 2
  -      end
  -      cmd = %Q["#{filename @command}" #{cdump ? "-S" : ""} #{@compile_options % {:funcname => funcname}} #{filename(infiles).map{|f| %Q["#{f}"]}.join(' ')}]
  -      puts cmd if Rake.verbose
  -      IO.popen(cmd, 'r+') do |io|
  -        out.puts io.read
  +
  +      puts "MRBC: Processing #{infiles.size} files"
  +      puts "MRBC: First file: #{filename(infiles.first)}" if infiles.size > 0
  +      response_file = nil
  +      if infiles.size > 100
  +        puts "MRBC: Creating response file for #{infiles.size} files (Windows command line limit workaround)"
  +        response_file = Tempfile.new(['mrbc', '.rsp'])
  +        infiles.each { |path| response_file.puts filename(path) }
  +        response_file.close
  +        puts "MRBC: Response file created at #{response_file.path}"
  +        infiles = ["@#{response_file.path}"]
  +      else
  +        puts "MRBC: Not using response file (file count <= 100)"
         end
  -      # if mrbc execution fail, drop the file
  -      unless $?.success?
  -        rm_f out.path
  -        fail "Command failed with status (#{$?.exitstatus}): [#{cmd[0,42]}...]"
  +
  +      begin
  +        infiles.each_with_index do |f, i|
  +          _pp i == 0 ? "MRBC" : "", f.relative_path, indent: 2
  +        end
  +        cmd = %Q["#{filename @command}" #{cdump ? "-S" : ""} #{@compile_options % {:funcname => funcname}} #{filename(infiles).map{|f| %Q["#{f}"]}.join(' ')}]
  +        puts cmd if Rake.verbose
  +        puts "MRBC: Command length: #{cmd.length}"
  +        IO.popen(cmd, 'r+') do |io|
  +          out.puts io.read
  +        end
  +        # if mrbc execution fail, drop the file
  +        unless $?.success?
  +          rm_f out.path
  +          fail "Command failed with status (#{$?.exitstatus}): [#{cmd[0,42]}...]"
  +        end
  +      ensure
  +        response_file&.close!
         end
       end
     end
PATCH

file :mruby do
  puts "DEBUG: Running :mruby task, downloading mruby #{MRUBY_VERSION}"
  if RUBY_PLATFORM.include?('solaris')
    puts "DEBUG: Using git clone for solaris"
    sh "git clone --branch=#{MRUBY_VERSION} https://github.com/mruby/mruby"
    patch = 'gpatch'
  else
    puts "DEBUG: Using curl to download mruby tarball"
    sh "curl -L --fail --retry 3 --retry-delay 1 https://github.com/mruby/mruby/archive/#{MRUBY_VERSION}.tar.gz -s -o - | tar zxf -"
    puts "DEBUG: Contents of extracted directory: #{Dir.entries('.').join(', ')}"
    puts "DEBUG: Contents of mruby-#{MRUBY_VERSION}: #{Dir.entries('mruby-3.0.0').join(', ')}" if Dir.exist?('mruby-3.0.0')
    puts "DEBUG: Moving mruby-#{MRUBY_VERSION} to mruby"
    FileUtils.mv("mruby-#{MRUBY_VERSION}", 'mruby')
    patch = 'patch'
  end

end

CROSS_TARGETS = [
  'linux-x86_64',
  'linux-i386',
  'linux-armhf',
  'linux-aarch64',
  'darwin-x86_64',
  'darwin-aarch64',
  'windows-x86_64',
  'windows-i386',
].freeze

STRIP_TARGETS = [
  'linux-x86_64',
  'linux-i386',
  'windows-x86_64',
  'windows-i386',
].freeze

# avoid redefining constants in mruby Rakefile
mruby_root = File.expand_path(ENV['MRUBY_ROOT'] || "#{Dir.pwd}/mruby")
mruby_config = File.expand_path(ENV['MRUBY_CONFIG'] || 'build_config.rb')
ENV['MRUBY_ROOT'] = mruby_root
ENV['MRUBY_CONFIG'] = mruby_config
puts "DEBUG: mruby_root = #{mruby_root}"
puts "DEBUG: Dir.exist?(mruby_root) = #{Dir.exist?(mruby_root)}"
puts "DEBUG: Listing mruby_root parent: #{Dir.entries(File.dirname(mruby_root)).join(', ')}" if File.exist?(File.dirname(mruby_root))
if Dir.exist?(mruby_root) && !File.exist?("#{mruby_root}/Rakefile")
  puts "DEBUG: mruby directory exists but Rakefile missing, removing directory"
  puts "DEBUG: Before removal, directory listing: #{Dir.entries(mruby_root).join(', ')}"
  FileUtils.rm_rf(mruby_root)
  puts "DEBUG: After removal, Dir.exist?(mruby_root) = #{Dir.exist?(mruby_root)}"
  if Dir.exist?(mruby_root)
    puts "DEBUG: ERROR: Directory still exists after rm_rf!"
  end
end
Rake::Task[:mruby].invoke unless File.exist?("#{mruby_root}/Rakefile")

# Apply patches to mruby source code (fixes for Windows command line length)
if MRUBY_VERSION == '3.0.0' && Dir.exist?(mruby_root)
  puts "DEBUG: Applying mruby patches for version #{MRUBY_VERSION}"
  patch_cmd = RUBY_PLATFORM.include?('solaris') ? 'gpatch' : 'patch'
  
  # Apply build.rb patch (PR #5318) only if not already patched
  build_patch_file = "#{mruby_root}/lib/mruby/build.rb"
  if File.exist?(build_patch_file)
    content = File.read(build_patch_file)
    unless content.include?('@mrbcfile || fail("external mrbc')
      IO.popen([patch_cmd, '-p0', '-f'], 'w') do |io|
        io.write(MRUBY_BUILD_PATCH)
      end
      unless $?.success?
        raise "Failed to apply mruby build patch"
      end
      puts "DEBUG: Applied mruby build patch"
    else
      puts "DEBUG: mruby build patch already applied, skipping"
    end
  end
  
  # Apply command.rb patch (Windows response file support) only if not already patched
  command_patch_file = "#{mruby_root}/lib/mruby/build/command.rb"
  if File.exist?(command_patch_file)
    content = File.read(command_patch_file)
    unless content.include?('MRBC: Processing')
      IO.popen([patch_cmd, '-p0', '-f'], 'w') do |io|
        io.write(MRUBY_COMMAND_PATCH)
      end
      unless $?.success?
        raise "Failed to apply mruby command patch"
      end
      puts "DEBUG: Applied mruby command patch"
    else
      puts "DEBUG: mruby command patch already applied, skipping"
    end
  end
  
  # Verify patch applied
  patched_file = "#{mruby_root}/lib/mruby/build/command.rb"
  if File.exist?(patched_file)
    content = File.read(patched_file)
    unless content.include?('MRBC: Processing')
      raise "Patch verification failed: command.rb not properly patched"
    end
    puts "DEBUG: mruby patches verified"
  end
end
puts "DEBUG: After task invocation, Dir.exist?(mruby_root) = #{Dir.exist?(mruby_root)}"
Dir.chdir(mruby_root)
puts "DEBUG: Checking if Rakefile exists: #{File.exist?('Rakefile')}"
puts "DEBUG: Listing mruby directory: #{Dir.entries('.').join(', ')}"
puts "DEBUG: Loading Rakefile from #{mruby_root}/Rakefile"
load "#{mruby_root}/Rakefile"

desc 'run serverspec'
task 'test:integration' do
  Dir.chdir(__dir__) do
    sh 'bundle check || bundle install -j4'
    sh 'bundle exec rspec'
  end
end

desc 'Run RuboCop'
task :rubocop do
  Dir.chdir(__dir__) do
    sh 'bundle check || bundle install -j4'
    sh 'bundle exec rubocop'
  end
end

desc 'Run RuboCop with auto-correct'
task 'rubocop:autocorrect' do
  Dir.chdir(__dir__) do
    sh 'bundle check || bundle install -j4'
    sh 'bundle exec rubocop -A'
  end
end

desc 'Run tests and linting'
task test: ['rubocop', 'test:integration']

desc 'compile binary'
task compile: :all

desc 'cleanup'
task :clean do
  sh 'rake deep_clean'
end

desc 'cross compile for release'
task 'release:build' => CROSS_TARGETS.map { |target| "release:build:#{target}" }

CROSS_TARGETS.each do |target|
  desc "Build for #{target}"
  task "release:build:#{target}" do
    Dir.chdir(__dir__) do
      # Workaround: Running `rake compile` twice breaks mattn/mruby-onig-regexp
      FileUtils.rm_rf('mruby/build')

      sh "rake compile BUILD_TARGET=#{target.shellescape}"

      FileUtils.mkdir_p('mitamae-build')
      os, arch = target.split('-', 2)

      # Handle Windows executables with .exe extension
      bin = if os == 'windows'
              "mitamae-build/mitamae-#{arch}-#{os}.exe"
            else
              "mitamae-build/mitamae-#{arch}-#{os}"
            end

      # Copy the binary from build directory
      source_bin = if os == 'windows'
                     "mruby/build/#{target.shellescape}/bin/mitamae.exe"
                   else
                     "mruby/build/#{target.shellescape}/bin/mitamae"
                   end
      sh "cp #{source_bin.shellescape} #{bin.shellescape}"

      if STRIP_TARGETS.include?(target)
        if os == 'windows'
          # Use appropriate strip command for Windows binaries if available
          if system('which x86_64-w64-mingw32-strip >/dev/null 2>&1')
            sh "x86_64-w64-mingw32-strip --strip-unneeded #{bin.shellescape}"
          elsif system('which i686-w64-mingw32-strip >/dev/null 2>&1') && arch == 'i386'
            sh "i686-w64-mingw32-strip --strip-unneeded #{bin.shellescape}"
          else
            puts 'Warning: No appropriate strip command found for Windows binaries'
          end
        else
          sh "strip --strip-unneeded #{bin.shellescape}"
        end
      end
    end
  end
end

desc 'compress binaries in mitamae-build'
task 'release:compress' do
  Dir.chdir(File.expand_path('./mitamae-build', __dir__)) do
    Dir.glob('mitamae-*').each do |path|
      sh "tar zcvf #{path}.tar.gz #{path}"
    end
  end
end
