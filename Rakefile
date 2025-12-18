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

    IO.popen([patch, '-p0'], 'w') do |io|
      io.write(<<~'PATCH')
        --- mruby/lib/mruby/build/command.rb	2025-12-18 14:35:59
        +++ mruby/lib/mruby/build/command.rb	2025-12-18 14:36:07
        @@ -1,9 +1,11 @@
         require 'forwardable'
        +require 'tempfile'

         module MRuby
           class Command
             include Rake::DSL
             extend Forwardable
        +
             def_delegators :@build, :filename, :objfile, :libfile, :exefile
             attr_accessor :build, :command

         @@ -14,10 +16,10 @@
             # clone is deep clone without @build
             def clone
               target = super
        -      excepts = %w(@build)
        +      excepts = ['@build']
               instance_variables.each do |attr|
                 unless excepts.include?(attr.to_s)
        -          val = Marshal::load(Marshal.dump(instance_variable_get(attr))) # deep clone
        +          val = Marshal.load(Marshal.dump(instance_variable_get(attr))) # deep clone
                   target.instance_variable_set(attr, val)
                 end
               end
         @@ -33,28 +35,28 @@
             end

             private
        -    def _run(options, params={})
        +
        +    def _run(options, params = {})
               sh "#{build.filename(command)} #{options % params}"
             end
           end

           class Command::Compiler < Command
        -    attr_accessor :label, :flags, :include_paths, :defines, :source_exts
        -    attr_accessor :compile_options, :option_define, :option_include_path, :out_ext
        -    attr_accessor :cxx_compile_flag, :cxx_exception_flag, :cxx_invalid_flags
        +    attr_accessor :label, :flags, :include_paths, :defines, :source_exts, :compile_options, :option_define,
        +                  :option_include_path, :out_ext, :cxx_compile_flag, :cxx_exception_flag, :cxx_invalid_flags
             attr_writer :preprocess_options

        -    def initialize(build, source_exts=[], label: "CC")
        +    def initialize(build, source_exts = [], label: 'CC')
               super(build)
               @command = ENV['CC'] || 'cc'
               @label = label
               @flags = [ENV['CFLAGS'] || []]
               @source_exts = source_exts
               @include_paths = ["#{MRUBY_ROOT}/include"]
        -      @defines = %w()
        -      @option_include_path = %q[-I"%s"]
        -      @option_define = %q[-D"%s"]
        -      @compile_options = %q[%{flags} -o "%{outfile}" -c "%{infile}"]
        +      @defines = []
        +      @option_include_path = '-I"%s"'
        +      @option_define = '-D"%s"'
        +      @compile_options = '%<flags>s -o "%<outfile>s" -c "%<infile>s"'
               @cxx_invalid_flags = []
               @out_ext = build.exts.object
             end
         @@ -62,7 +64,7 @@
             alias header_search_paths include_paths

             def preprocess_options
        -      @preprocess_options ||= @compile_options.sub(/(?:\A|\s)\K-c(?=\s)/, "-E -P")
        +      @preprocess_options ||= @compile_options.sub(/(?:\A|\s)\K-c(?=\s)/, '-E -P')
             end

             def search_header_path(name)
         @@ -76,46 +78,46 @@
               path && build.filename("#{path}/#{name}").sub(/^"(.*)"$/, '\1')
             end

        -    def all_flags(_defines=[], _include_paths=[], _flags=[])
        -      define_flags = [defines, _defines].flatten.map{ |d| option_define % d }
        +    def all_flags(_defines = [], _include_paths = [], _flags = [])
        +      define_flags = [defines, _defines].flatten.map { |d| option_define % d }
               include_path_flags = [include_paths, _include_paths].flatten.map do |f|
                 option_include_path % filename(f)
               end
               [flags, define_flags, include_path_flags, _flags].flatten.join(' ')
             end

        -    def run(outfile, infile, _defines=[], _include_paths=[], _flags=[])
        +    def run(outfile, infile, _defines = [], _include_paths = [], _flags = [])
               mkdir_p File.dirname(outfile)
               flags = all_flags(_defines, _include_paths, _flags)
               if object_ext?(outfile)
                 label = @label
                 opts = compile_options
               else
        -        label = "CPP"
        +        label = 'CPP'
                 opts = preprocess_options
        -        flags << " -DMRB_PRESYM_SCANNING"
        +        flags << ' -DMRB_PRESYM_SCANNING'
               end
               _pp label, infile.relative_path, outfile.relative_path
               _run opts, flags: flags, infile: filename(infile), outfile: filename(outfile)
             end

        -    def define_rules(build_dir, source_dir='', out_ext=build.exts.object)
        -      gemrake = File.join(source_dir, "mrbgem.rake")
        -      rakedep = File.exist?(gemrake) ? [ gemrake ] : []
        +    def define_rules(build_dir, source_dir = '', out_ext = build.exts.object)
        +      gemrake = File.join(source_dir, 'mrbgem.rake')
        +      rakedep = File.exist?(gemrake) ? [gemrake] : []

        -      if build_dir.include? "mrbgems/"
        -        generated_file_matcher = Regexp.new("^#{Regexp.escape build_dir}/(.*)#{Regexp.escape out_ext}$")
        -      else
        -        generated_file_matcher = Regexp.new("^#{Regexp.escape build_dir}/(?!mrbgems/.+/)(.*)#{Regexp.escape out_ext}$")
        -      end
        -      source_exts.each do |ext, compile|
        +      generated_file_matcher = if build_dir.include? 'mrbgems/'
        +                                 Regexp.new("^#{Regexp.escape build_dir}/(.*)#{Regexp.escape out_ext}$")
        +                               else
        +                                 Regexp.new("^#{Regexp.escape build_dir}/(?!mrbgems/.+/)(.*)#{Regexp.escape out_ext}$")
        +                               end
        +      source_exts.each do |ext, _compile|
                 rule generated_file_matcher => [
                   proc { |file|
                     file.sub(generated_file_matcher, "#{source_dir}/\\1#{ext}")
                   },
                   proc { |file|
                     get_dependencies(file) + rakedep
        -          }
        +          },
                 ] do |t|
                   run t.name, t.prerequisites.first
                 end
         @@ -126,7 +128,7 @@
                 },
                 proc { |file|
                   get_dependencies(file) + rakedep
        -          }
        +          },
                 ] do |t|
                   run t.name, t.prerequisites.first
                 end
         @@ -157,10 +159,10 @@
             #   /src/value_array.h:
             #
             def get_dependencies(file)
        -      dep_file = file.ext(".d")
        +      dep_file = file.ext('.d')
               return [MRUBY_CONFIG] unless object_ext?(file) && File.exist?(dep_file)

        -      deps = File.read(dep_file).gsub("\\\n ", "").split("\n").map do |dep_line|
        +      deps = File.read(dep_file).gsub("\\\n ", '').split("\n").map do |dep_line|
                 # dep_line:
                 # - "/build/host/src/array.o:   /src/array.c   /include/mruby/common.h ..."
                 # - ""
         @@ -179,22 +181,23 @@
           end

           class Command::Linker < Command
        -    attr_accessor :flags, :library_paths, :flags_before_libraries, :libraries, :flags_after_libraries
        -    attr_accessor :link_options, :option_library, :option_library_path
        +    attr_accessor :flags, :library_paths, :flags_before_libraries, :libraries, :flags_after_libraries, :link_options,
        +                  :option_library, :option_library_path

             def initialize(build)
               super
               @command = ENV['LD'] || 'ld'
        -      @flags = (ENV['LDFLAGS'] || [])
        -      @flags_before_libraries, @flags_after_libraries = [], []
        +      @flags = ENV['LDFLAGS'] || []
        +      @flags_before_libraries = []
        +      @flags_after_libraries = []
               @libraries = []
               @library_paths = []
        -      @option_library = %q[-l"%s"]
        -      @option_library_path = %q[-L"%s"]
        -      @link_options = %Q[%{flags} -o "%{outfile}" %{objs} %{flags_before_libraries} %{libs} %{flags_after_libraries}]
        +      @option_library = '-l"%s"'
        +      @option_library_path = '-L"%s"'
        +      @link_options = %(%<flags>s -o "%<outfile>s" %<objs>s %<flags_before_libraries>s %<libs>s %<flags_after_libraries>s)
             end

        -    def all_flags(_library_paths=[], _flags=[])
        +    def all_flags(_library_paths = [], _flags = [])
               library_path_flags = [library_paths, _library_paths].flatten.map do |f|
                 option_library_path % filename(f)
               end
         @@ -202,23 +205,24 @@
             end

             def library_flags(_libraries)
        -      [libraries, _libraries].flatten.map{ |d| option_library % d }.join(' ')
        +      [libraries, _libraries].flatten.map { |d| option_library % d }.join(' ')
             end

             def run_attrs
               [@libraries, @library_paths, @flags, @flags_before_libraries, @flags_after_libraries]
             end

        -    def run(outfile, objfiles, _libraries=[], _library_paths=[], _flags=[], _flags_before_libraries=[], _flags_after_libraries=[])
        +    def run(outfile, objfiles, _libraries = [], _library_paths = [], _flags = [], _flags_before_libraries = [],
        +            _flags_after_libraries = [])
               mkdir_p File.dirname(outfile)
               library_flags = [libraries, _libraries].flatten.map { |d| option_library % d }

        -      _pp "LD", outfile.relative_path
        -      _run link_options, { :flags => all_flags(_library_paths, _flags),
        -                            :outfile => filename(outfile) , :objs => filename(objfiles).map{|f| %Q["#{f}"]}.join(' '),
        -                            :flags_before_libraries => [flags_before_libraries, _flags_before_libraries].flatten.join(' '),
        -                            :flags_after_libraries => [flags_after_libraries, _flags_after_libraries].flatten.join(' '),
        -                            :libs => library_flags.join(' ') }
        +      _pp 'LD', outfile.relative_path
        +      _run link_options, { flags: all_flags(_library_paths, _flags),
        +                           outfile: filename(outfile), objs: filename(objfiles).map { |f| %("#{f}") }.join(' '),
        +                           flags_before_libraries: [flags_before_libraries, _flags_before_libraries].flatten.join(' '),
        +                           flags_after_libraries: [flags_after_libraries, _flags_after_libraries].flatten.join(' '),
        +                           libs: library_flags.join(' ') }
             end
           end

         @@ -228,13 +232,13 @@
             def initialize(build)
               super
               @command = ENV['AR'] || 'ar'
        -      @archive_options = 'rs "%{outfile}" %{objs}'
        +      @archive_options = 'rs "%<outfile>s" %<objs>s'
             end

             def run(outfile, objfiles)
               mkdir_p File.dirname(outfile)
        -      _pp "AR", outfile.relative_path
        -      _run archive_options, { :outfile => filename(outfile), :objs => filename(objfiles).map{|f| %Q["#{f}"]}.join(' ') }
        +      _pp 'AR', outfile.relative_path
        +      _run archive_options, { outfile: filename(outfile), objs: filename(objfiles).map { |f| %("#{f}") }.join(' ') }
             end
           end

         @@ -244,13 +248,13 @@
             def initialize(build)
               super
               @command = 'bison'
        -      @compile_options = %q[-o "%{outfile}" "%{infile}"]
        +      @compile_options = '-o "%<outfile>s" "%<infile>s"'
             end

             def run(outfile, infile)
               mkdir_p File.dirname(outfile)
        -      _pp "YACC", infile.relative_path, outfile.relative_path
        -      _run compile_options, { :outfile => filename(outfile) , :infile => filename(infile) }
        +      _pp 'YACC', infile.relative_path, outfile.relative_path
        +      _run compile_options, { outfile: filename(outfile), infile: filename(infile) }
             end
           end

         @@ -260,58 +264,58 @@
             def initialize(build)
               super
               @command = 'gperf'
        -      @compile_options = %q[-L ANSI-C -C -p -j1 -i 1 -g -o -t -N mrb_reserved_word -k"1,3,$" "%{infile}" > "%{outfile}"]
        +      @compile_options = '-L ANSI-C -C -p -j1 -i 1 -g -o -t -N mrb_reserved_word -k"1,3,$" "%<infile>s" > "%<outfile>s"'
             end

             def run(outfile, infile)
               mkdir_p File.dirname(outfile)
        -      _pp "GPERF", infile.relative_path, outfile.relative_path
        -      _run compile_options, { :outfile => filename(outfile) , :infile => filename(infile) }
        +      _pp 'GPERF', infile.relative_path, outfile.relative_path
        +      _run compile_options, { outfile: filename(outfile), infile: filename(infile) }
             end
           end

           class Command::Git < Command
        -    attr_accessor :flags
        -    attr_accessor :clone_options, :pull_options, :checkout_options, :checkout_detach_options, :reset_options
        +    attr_accessor :flags, :clone_options, :pull_options, :checkout_options, :checkout_detach_options, :reset_options

             def initialize(build)
               super
               @command = 'git'
        -      @flags = %w[]
        -      @clone_options = "clone %{flags} %{url} %{dir}"
        -      @pull_options = "--git-dir %{repo_dir}/.git --work-tree %{repo_dir} pull"
        -      @checkout_options = "--git-dir %{repo_dir}/.git --work-tree %{repo_dir} checkout %{checksum_hash}"
        -      @checkout_detach_options = "--git-dir %{repo_dir}/.git --work-tree %{repo_dir} checkout --detach %{checksum_hash}"
        -      @reset_options = "--git-dir %{repo_dir}/.git --work-tree %{repo_dir} reset %{checksum_hash}"
        +      @flags = []
        +      @clone_options = 'clone %<flags>s %<url>s %<dir>s'
        +      @pull_options = '--git-dir %<repo_dir>s/.git --work-tree %<repo_dir>s pull'
        +      @checkout_options = '--git-dir %<repo_dir>s/.git --work-tree %<repo_dir>s checkout %<checksum_hash>s'
        +      @checkout_detach_options = '--git-dir %<repo_dir>s/.git --work-tree %<repo_dir>s checkout --detach %<checksum_hash>s'
        +      @reset_options = '--git-dir %<repo_dir>s/.git --work-tree %<repo_dir>s reset %<checksum_hash>s'
             end

             def run_clone(dir, url, _flags = [])
        -      _pp "GIT", url, dir.relative_path
        -      _run clone_options, { :flags => [flags, _flags].flatten.join(' '), :url => shellquote(url), :dir => shellquote(filename(dir)) }
        +      _pp 'GIT', url, dir.relative_path
        +      _run clone_options,
        +           { flags: [flags, _flags].flatten.join(' '), url: shellquote(url), dir: shellquote(filename(dir)) }
             end

             def run_pull(dir, url)
        -      _pp "GIT PULL", url, dir.relative_path
        -      _run pull_options, { :repo_dir => shellquote(dir) }
        +      _pp 'GIT PULL', url, dir.relative_path
        +      _run pull_options, { repo_dir: shellquote(dir) }
             end

             def run_checkout(dir, checksum_hash)
        -      _pp "GIT CHECKOUT", dir, checksum_hash
        -      _run checkout_options, { :checksum_hash => checksum_hash, :repo_dir => shellquote(dir) }
        +      _pp 'GIT CHECKOUT', dir, checksum_hash
        +      _run checkout_options, { checksum_hash: checksum_hash, repo_dir: shellquote(dir) }
             end

             def run_checkout_detach(dir, checksum_hash)
        -      _pp "GIT CHECKOUT DETACH", dir, checksum_hash
        -      _run checkout_detach_options, { :checksum_hash => checksum_hash, :repo_dir => shellquote(dir) }
        +      _pp 'GIT CHECKOUT DETACH', dir, checksum_hash
        +      _run checkout_detach_options, { checksum_hash: checksum_hash, repo_dir: shellquote(dir) }
             end

             def run_reset_hard(dir, checksum_hash)
        -      _pp "GIT RESET", dir, checksum_hash
        -      _run reset_options, { :checksum_hash => checksum_hash, :repo_dir => shellquote(dir) }
        +      _pp 'GIT RESET', dir, checksum_hash
        +      _run reset_options, { checksum_hash: checksum_hash, repo_dir: shellquote(dir) }
             end

             def commit_hash(dir)
        -      `#{@command} --git-dir #{shellquote(dir +'/.git')} --work-tree #{shellquote(dir)} rev-parse --verify HEAD`.strip
        +      `#{@command} --git-dir #{shellquote(dir + '/.git')} --work-tree #{shellquote(dir)} rev-parse --verify HEAD`.strip
             end

             def current_branch(dir)
         @@ -325,45 +329,65 @@
             def initialize(build)
               super
               @command = nil
        -      @compile_options = "-B%{funcname} -o-"
        +      @compile_options = '-B%<funcname>s -o-'
             end

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
        +        puts 'MRBC: Not using response file (file count <= 100)'
               end
        -      # if mrbc execution fail, drop the file
        -      unless $?.success?
        -        rm_f out.path
        -        fail "Command failed with status (#{$?.exitstatus}): [#{cmd[0,42]}...]"
        +
        +      begin
        +        infiles.each_with_index do |f, i|
        +          _pp i == 0 ? 'MRBC' : '', f.relative_path, indent: 2
        +        end
        +        cmd = %("#{filename @command}" #{'-S' if cdump} #{format(@compile_options,
        +                                                                 funcname: funcname)} #{filename(infiles).map do |f|
        +                                                                                        %("#{f}")
        +                                                                                      end.join(' ')})
        +        puts cmd if Rake.verbose
        +        puts "MRBC: Command length: #{cmd.length}"
        +        IO.popen(cmd, 'r+') do |io|
        +          out.puts io.read
        +        end
        +        # if mrbc execution fail, drop the file
        +        unless $?.success?
        +          rm_f out.path
        +          raise "Command failed with status (#{$?.exitstatus}): [#{cmd[0, 42]}...]"
        +        end
        +      ensure
        +        response_file&.close!
               end
             end
           end

           class Command::CrossTestRunner < Command
        -    attr_accessor :runner_options
        -    attr_accessor :verbose_flag
        -    attr_accessor :flags
        +    attr_accessor :runner_options, :verbose_flag, :flags

             def initialize(build)
               super
               @command = nil
        -      @runner_options = '%{flags} %{infile}'
        +      @runner_options = '%<flags>s %<infile>s'
               @verbose_flag = ''
               @flags = []
             end

             def run(testbinfile)
        -      puts "TEST for " + @build.name
        -      _run runner_options, { :flags => [flags, verbose_flag].flatten.join(' '), :infile => testbinfile }
        +      puts 'TEST for ' + @build.name
        +      _run runner_options, { flags: [flags, verbose_flag].flatten.join(' '), infile: testbinfile }
             end
           end
        -
         end
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
