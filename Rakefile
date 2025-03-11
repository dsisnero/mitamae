require 'fileutils'
require 'shellwords'

MRUBY_VERSION = '3.0.0'

file :mruby do
  version_file = File.join(__dir__, '.mruby_version')
  current_version = MRUBY_VERSION
  
  # Check if we already have the correct version
  if Dir.exist?('mruby') && File.exist?(version_file) && File.read(version_file).strip == current_version
    puts "MRuby version #{current_version} already downloaded, skipping download"
  else
    # Clean up any existing mruby directory if it's the wrong version
    if Dir.exist?('mruby')
      puts "Removing existing mruby directory (wrong version or corrupted)"
      FileUtils.rm_rf('mruby')
    end
    
    # Download and setup mruby
    if RUBY_PLATFORM.match(/solaris/)
      sh "git clone --branch=#{MRUBY_VERSION} https://github.com/mruby/mruby"
      patch = 'gpatch'
    else
      sh "curl -L --fail --retry 3 --retry-delay 1 https://github.com/mruby/mruby/archive/#{MRUBY_VERSION}.tar.gz -s -o - | tar zxf -"
      FileUtils.mv("mruby-#{MRUBY_VERSION}", 'mruby')
      patch = 'patch'
    end

    # Patch: https://github.com/mruby/mruby/pull/5318
    if MRUBY_VERSION == '3.0.0'
      IO.popen([patch, '-p0'], 'w') do |io|
        io.write(<<-'EOS')
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
        EOS
      end
    end
    
    # Save the version we just installed
    File.write(version_file, current_version)
  end
end

CROSS_TARGETS = %w[
  linux-x86_64
  linux-i386
  linux-armhf
  linux-aarch64
  darwin-x86_64
  darwin-aarch64
  windows-x86_64
  windows-i386
]

STRIP_TARGETS = %w[
  linux-x86_64
  linux-i386
  windows-x86_64
  windows-i386
]

# avoid redefining constants in mruby Rakefile
mruby_root = File.expand_path(ENV['MRUBY_ROOT'] || "#{Dir.pwd}/mruby")
mruby_config = File.expand_path(ENV['MRUBY_CONFIG'] || 'build_config.rb')
ENV['MRUBY_ROOT'] = mruby_root
ENV['MRUBY_CONFIG'] = mruby_config
Rake::Task[:mruby].invoke unless Dir.exist?(mruby_root)
Dir.chdir(mruby_root)
load "#{mruby_root}/Rakefile"

desc 'run serverspec'
task 'test:integration' do
  Dir.chdir(__dir__) do
    sh 'bundle check || bundle install -j4'
    sh 'bundle exec rspec'
  end
end

desc 'Run Windows tests in Docker container'
task 'test:windows' do
  Dir.chdir(__dir__) do
    # For local Windows testing without Docker
    if ENV['NO_DOCKER']
      sh 'bundle check || bundle install -j4'
      sh 'bundle exec rspec spec/windows/'
    elsif RUBY_PLATFORM =~ /linux/ && ENV['DOCKER_HOST'].nil?
      # Use QEMU emulation for Windows containers on Linux
      sh 'docker run --privileged --rm tonistiigi/binfmt --install all'
      sh 'docker buildx create --use --name windows-builder || echo "Builder may already exist"'
      
      sh <<~CMD
        docker buildx build --platform windows/amd64 \\
          -t mitamae-windows-tester \\
          --build-arg RUBY_VERSION=3.2.2 \\
          -f Dockerfile.windows .
      CMD

      sh <<~CMD
        docker run --rm -it \\
          --platform windows/amd64 \\
          -v "#{Dir.pwd}:/mitamae" \\
          -e DOCKER_WINDOWS_CONTAINER=1 \\
          mitamae-windows-tester \\
          powershell -Command "cd /mitamae; bundle exec rspec spec/windows"
      CMD
    else
      # Native Windows container execution
      sh <<~CMD
        docker build -t mitamae-windows-tester \\
          --build-arg RUBY_VERSION=3.2.2 \\
          -f Dockerfile.windows .
      CMD

      sh <<~CMD
        docker run --rm -it \\
          -v "#{Dir.pwd}:/mitamae" \\
          -e DOCKER_WINDOWS_CONTAINER=1 \\
          mitamae-windows-tester \\
          powershell -Command "cd /mitamae; bundle exec rspec spec/windows"
      CMD
    end
  end
end

desc 'compile binary'
task compile: :all

desc 'cleanup build artifacts'
task :clean do
  # Only clean the build directory, not the entire mruby
  FileUtils.rm_rf('mruby/build') if Dir.exist?('mruby/build')
end

desc 'clobber all downloads and build artifacts'
task :clobber => :clean do
  # Remove mruby completely and the version file
  FileUtils.rm_rf('mruby') if Dir.exist?('mruby')
  FileUtils.rm_f('.mruby_version') if File.exist?('.mruby_version')
end

desc 'cross compile for release'
task 'release:build' => CROSS_TARGETS.map { |target| "release:build:#{target}" }

# Windows-specific build tasks
namespace :windows do
  desc "Build and test mitamae for Windows"
  task :test => :clean do
    ENV['OS'] = 'Windows_NT' unless ENV['OS']
    # Make sure we're using the right build target
    ENV['BUILD_TARGET'] = 'windows-x86_64'
    sh "rake compile"
  end

  desc "Build mitamae for Windows"
  task :build do
    ENV['OS'] = 'Windows_NT' unless ENV['OS']
    sh "rake compile BUILD_TARGET=windows-x86_64"
    # Add any Windows-specific post-build steps here
  end
end

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
      
      # Handle Windows targets
      if os == 'windows'
        # Main executable
        bin_exe = "mitamae-build/mitamae-#{arch}-#{os}.exe"
        source_bin = "mruby/build/#{target.shellescape}/bin/mitamae.exe"

        # Batch file bootstrap
        File.write("mitamae-build/mitamae-#{arch}-#{os}.bat", <<~BAT)
          @echo off
          setlocal enabledelayedexpansion
          set MITAMAE_EXE=%~dp0mitamae-#{arch}-#{os}.exe
          
          if not exist "!MITAMAE_EXE!" (
            echo Error: Mitamae executable not found at "!MITAMAE_EXE!"
            exit /b 1
          )
          
          "!MITAMAE_EXE!" %*
        BAT

        # PowerShell bootstrap
        File.write("mitamae-build/mitamae-#{arch}-#{os}.ps1", <<~PS1)
          [CmdletBinding()]
          param(
              [Parameter(ValueFromRemainingArguments=$true)]
              [string[]]$Arguments
          )

          $ErrorActionPreference = 'Stop'
          $MitamaeExe = Join-Path $PSScriptRoot "mitamae-#{arch}-#{os}.exe"
          
          if (-not (Test-Path $MitamaeExe)) {
              Write-Error "Mitamae executable not found at: $MitamaeExe"
              exit 1
          }
          
          & $MitamaeExe $Arguments
        PS1

        # Copy main binary
        sh "cp #{source_bin.shellescape} #{bin_exe.shellescape}"
      else
        # Unix targets
        bin = "mitamae-build/mitamae-#{arch}-#{os}"
        source_bin = "mruby/build/#{target.shellescape}/bin/mitamae"
        
        # Create shell wrapper script
        File.write("#{bin}.sh", <<~SH)
          #!/bin/sh
          exec "$(dirname "$0")/mitamae-#{arch}-#{os}" "$@"
        SH
        FileUtils.chmod(0755, "#{bin}.sh")
        
        # Copy main binary
        sh "cp #{source_bin.shellescape} #{bin.shellescape}"
      end

      if STRIP_TARGETS.include?(target)
        if os == 'windows'
          # Use appropriate strip command for Windows binaries if available
          if system('which x86_64-w64-mingw32-strip >/dev/null 2>&1')
            sh "x86_64-w64-mingw32-strip --strip-unneeded #{bin.shellescape}"
          elsif system('which i686-w64-mingw32-strip >/dev/null 2>&1') && arch == 'i386'
            sh "i686-w64-mingw32-strip --strip-unneeded #{bin.shellescape}"
          else
            puts "Warning: No appropriate strip command found for Windows binaries"
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
    # Group files by base name (without extension)
    files_by_base = {}
    Dir.glob('mitamae-*').each do |path|
      base = path.sub(/\.(exe|bat|ps1|sh)$/, '')
      files_by_base[base] ||= []
      files_by_base[base] << path
    end
    
    # Create archives with all related files
    files_by_base.each do |base, files|
      if base.include?('windows')
        # For Windows, include .exe, .bat and .ps1 files in the archive
        sh "tar zcvf #{base}.tar.gz #{files.join(' ')}"
      else
        # For Unix platforms, include the binary and .sh wrapper
        sh "tar zcvf #{base}.tar.gz #{files.join(' ')}"
      end
    end
  end
end
