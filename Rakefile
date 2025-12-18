# frozen_string_literal: true

require 'fileutils'
require 'shellwords'

MRUBY_VERSION = '3.0.0'

file :mruby do
  puts "DEBUG: Running :mruby task, downloading mruby #{MRUBY_VERSION}"
  if RUBY_PLATFORM.include?('solaris')
    puts "DEBUG: Using git clone for solaris"
    sh "git clone --branch=#{MRUBY_VERSION} https://github.com/mruby/mruby"
    patch = 'gpatch'
  else
    puts "DEBUG: Using curl to download mruby tarball"
    sh "curl -L --fail --retry 3 --retry-delay 1 https://github.com/mruby/mruby/archive/#{MRUBY_VERSION}.tar.gz -s -o - | tar zxf -"
    puts "DEBUG: Moving mruby-#{MRUBY_VERSION} to mruby"
    FileUtils.mv("mruby-#{MRUBY_VERSION}", 'mruby')
    patch = 'patch'
  end

  # Patch: https://github.com/mruby/mruby/pull/5318
  if MRUBY_VERSION == '3.0.0'
    IO.popen([patch, '-p0'], 'w') do |io|
      io.write(<<~'PATCH')
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
    end
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
Rake::Task[:mruby].invoke unless Dir.exist?(mruby_root)
puts "DEBUG: After task invocation, Dir.exist?(mruby_root) = #{Dir.exist?(mruby_root)}"
Dir.chdir(mruby_root)
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
