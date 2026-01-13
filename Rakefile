# frozen_string_literal: true

require 'fileutils'
require 'shellwords'
require 'tmpdir'

MRUBY_VERSION = '3.4.0'

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
  +        response_file = ::Tempfile.new(['mrbc', '.rsp'])
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

# Ensure mruby-print exists for mruby versions that no longer ship it as a core gem.
def ensure_mruby_print(mruby_root)
  print_dir = File.join(mruby_root, 'mrbgems', 'mruby-print')
  return if Dir.exist?(print_dir)

  puts "DEBUG: mruby-print missing; downloading external gem"
  Dir.mktmpdir('mruby-print') do |dir|
    tar_path = File.join(dir, 'mruby-print.tar.gz')
    system(
      'curl', '-L', '--fail', '--retry', '3', '--retry-delay', '1',
      'https://github.com/mruby/mruby-print/archive/refs/heads/master.tar.gz',
      '-o', tar_path,
      exception: true
    )
    system('tar', 'xf', tar_path, '-C', dir, exception: true)
    extracted = Dir.glob(File.join(dir, 'mruby-print-*')).find { |path| File.directory?(path) }
    raise 'Failed to extract mruby-print tarball' unless extracted

    FileUtils.mkdir_p(File.join(mruby_root, 'mrbgems'))
    FileUtils.rm_rf(print_dir)
    FileUtils.mv(extracted, print_dir)
  end
end

ensure_mruby_print(mruby_root) if Dir.exist?(mruby_root)

# Apply patches to mruby source code (fixes for Windows command line length)
if Dir.exist?(mruby_root)
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

  # Ensure command.rb has require 'tempfile' for response file support
  command_patch_file = "#{mruby_root}/lib/mruby/build/command.rb"
  if File.exist?(command_patch_file)
    content = File.read(command_patch_file)
    # Check if any require for tempfile exists (with single or double quotes)
    unless content =~ /require\s+['"]tempfile['"]/
      lines = content.lines
      # Insert after require 'forwardable' line
      require_line_index = lines.index { |line| line.include?("require 'forwardable'") }
      if require_line_index
        lines.insert(require_line_index + 1, "require 'tempfile'\n")
        File.write(command_patch_file, lines.join)
        puts "DEBUG: Added require 'tempfile' to command.rb"
      end
    end
  end

  # Apply command.rb patch (Windows response file support) only if not already patched
  if File.exist?(command_patch_file)
    content = File.read(command_patch_file)
    response_marker = "Tempfile.new(['mrbc', '.rsp'])"

    if content.include?('def run(out, infiles, funcname, cdump: true, static: false)')
      unless content.include?(response_marker)
        mrbc_method = <<~'RUBY'
          def run(out, infiles, funcname, cdump: true, static: false)
            @command ||= @build.mrbcfile
            infiles = [infiles].flatten
            response_file = nil
            if infiles.size > 100
              response_file = ::Tempfile.new(['mrbc', '.rsp'])
              infiles.each { |path| response_file.puts filename(path) }
              response_file.close
              infiles = ["@#{response_file.path}"]
            end

            begin
              infiles.each_with_index do |f, i|
                label = f.respond_to?(:relative_path) ? f.relative_path : f.to_s
                _pp i == 0 ? "MRBC" : "", label, indent: 2
              end
              opt = @compile_options % {funcname: funcname}
              opt << " -S" if cdump
              opt << " -s" if static
              cmd = %["#{filename @command}" #{opt} #{filename(infiles).map{|f| %["#{f}"]}.join(' ')}]
              puts cmd if Rake.verbose
              IO.popen(cmd, 'r') do |io|
                out.puts io.read
              end
              # if mrbc execution fail, drop the file
              unless $?.success?
                rm_f out.path
                fail "Command failed with status (#{$?.exitstatus}): [#{cmd[0,42]}...]"
              end
            ensure
              response_file&.close!
            end
          end
        RUBY

        mrbc_method_regex = /def run\(out, infiles, funcname, cdump: true, static: false\)\n(?:.*\n)*?    end/
        unless content.sub!(mrbc_method_regex, mrbc_method.rstrip)
          raise "Failed to apply mruby command patch (3.4.0 layout)"
        end
        File.write(command_patch_file, content)
        puts "DEBUG: Applied mruby command patch for 3.4.0 layout"
      else
        puts "DEBUG: mruby command patch already applied, skipping"
      end
    else
      unless content.include?(response_marker)
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
  end

  # Verify patch applied
  patched_file = "#{mruby_root}/lib/mruby/build/command.rb"
  if File.exist?(patched_file)
    content = File.read(patched_file)
    unless content.include?("Tempfile.new(['mrbc', '.rsp'])")
      raise "Patch verification failed: command.rb not properly patched"
    end
    # Patch mrbc.c to support @response files
  mrbc_patch_file = "#{mruby_root}/mrbgems/mruby-bin-mrbc/tools/mrbc/mrbc.c"
  if File.exist?(mrbc_patch_file)
    content = File.read(mrbc_patch_file)
    modified = false

    # Check if already patched with response_argv fields
    unless content.include?('response_argv')
      # Add fields to struct mrbc_args
      content.sub!(/unsigned int flags    : 4;\r?\n/, "unsigned int flags    : 4;\n  char **response_argv;\n  int response_argc;\n")
      # Remove any existing forward declaration of load_response_file (with or without static, with or without attributes)
      # Pattern matches: static int load_response_file(...); or int load_response_file(...); with possible attributes
      content.gsub!(/(?:static\s+)?int\s+(?:__attribute__\s*\(\([^)]+\)\)\s+)?load_response_file\s*\(mrb_state\s*\*\s*mrb\s*,\s*struct mrbc_args\s*\*\s*args\s*,\s*const char\s*\*\s*resp_path\s*\)\s*;/, '')
      # Add forward declaration with attributes after struct mrbc_args definition
      struct_end = content.index('};')
      if struct_end
        content.insert(struct_end + 2, "\nint __attribute__((used, noinline)) load_response_file(mrb_state *mrb, struct mrbc_args *args, const char *resp_path);\n")
        modified = true
        puts "DEBUG: Added forward declaration of load_response_file with attributes"
      end
      # Add dummy variable to force linker inclusion
      unless content.include?('dummy_load_response_file')
        # Insert after forward declaration
        decl_pos = content =~ /load_response_file\(mrb_state \*mrb, struct mrbc_args \*args, const char \*resp_path\);/
        if decl_pos
          line_end = content.index("\n", decl_pos)
          if line_end
            content.insert(line_end + 1, "\n/* Force linker to include load_response_file */\nint (*dummy_load_response_file)(mrb_state*, struct mrbc_args*, const char*) __attribute__((used)) = load_response_file;\n__attribute__((constructor)) static void force_load_response_file_constructor(void) {\n    static int (*ptr)(mrb_state*, struct mrbc_args*, const char*) = load_response_file;\n    (void)ptr;\n    __asm__ __volatile__(\"\" : : \"r\"(load_response_file));\n}\n")
            modified = true
            puts "DEBUG: Added dummy_load_response_file variable"
          end
        end
      end

      # Modify cleanup function
      content.sub!(/  mrb_free\(mrb, \(void\*\)args->outfile\);\n  mrb_close\(mrb\);\n/, "  mrb_free(mrb, (void*)args->outfile);\n  if (args->response_argv) {\n    int i;\n    for (i = 0; i < args->response_argc; ++i) {\n      mrb_free(mrb, args->response_argv[i]);\n    }\n    mrb_free(mrb, args->response_argv);\n    args->response_argv = NULL;\n  }\n  /* Reference to keep load_response_file in binary */\n  if (0) load_response_file(NULL, NULL, NULL);\n  (void)load_response_file;\n  (void)dummy_load_response_file;\n  mrb_close(mrb);\n")
      # Add load_response_file function before partial_hook
      partial_hook_start = content =~ /static\s+int\s*\r?\n\s*partial_hook/ ? $~.offset(0)[0] : nil
      if partial_hook_start
        load_response_func = <<~'C'.gsub(/^/, '')
int __attribute__((used, noinline))
load_response_file(mrb_state *mrb, struct mrbc_args *args, const char *resp_path)
{
  #warning "load_response_file is being compiled"
  FILE *f = fopen(resp_path, "r");
  if (!f) return 0;
  int count = 0;
  char line[1024];
  while (fgets(line, sizeof(line), f)) {
    char *p = strchr(line, '\n');
    if (p) *p = '\0';
    if (line[0] == '\0') continue;
    count++;
  }
  if (count == 0) {
    fclose(f);
    return -1;
  }
  rewind(f);
  char **lines = mrb_malloc(mrb, sizeof(char*) * count);
  int i = 0;
  while (fgets(line, sizeof(line), f)) {
    char *p = strchr(line, '\n');
    if (p) *p = '\0';
    if (line[0] == '\0') continue;
    lines[i] = mrb_malloc(mrb, strlen(line) + 1);
    strcpy(lines[i], line);
    i++;
  }
  fclose(f);
  args->response_argv = lines;
  args->response_argc = count;
  args->argv = lines;
  args->argc = count;
  args->idx = 0;
  return 1;
}
        C
        content.insert(partial_hook_start, load_response_func)
      end
      # Modify load_file to detect '@'
      content.sub!(/  char \*input = args->argv\[args->idx\];\n/, "  char *input = args->argv[args->idx];\n  if (input[0] == '@') {\n    int rsp_status = load_response_file(mrb, args, input + 1);\n    if (rsp_status <= 0) {\n      if (rsp_status < 0) {\n        fprintf(stderr, \"%s: response file is empty. (%s)\\n\", args->prog, input);\n      }\n      else {\n        fprintf(stderr, \"%s: cannot open response file. (%s)\\n\", args->prog, input);\n      }\n      return mrb_nil_value();\n    }\n    input = args->argv[args->idx];\n  }\n")
      modified = true
      puts "DEBUG: Patched mrbc.c with response file support"
    else
      puts "DEBUG: mrbc.c already patched, skipping"
    end

    # Ensure constructor exists even if dummy variable already present
    unless content.include?('force_load_response_file_constructor')
      # Find dummy variable line
      dummy_pos = content.index('dummy_load_response_file')
      if dummy_pos
        line_end = content.index("\n", dummy_pos)
        if line_end
          content.insert(line_end + 1, "\n__attribute__((constructor)) static void force_load_response_file_constructor(void) {\n    static int (*ptr)(mrb_state*, struct mrbc_args*, const char*) = load_response_file;\n    (void)ptr;\n    __asm__ __volatile__(\"\" : : \"r\"(load_response_file));\n}\n")
          modified = true
          puts "DEBUG: Added missing constructor"
        end
      end
    end

    # Ensure dummy_load_response_file variable exists (even if already patched)
    unless content.include?('dummy_load_response_file')
      # Find forward declaration of load_response_file
      decl_pos = content =~ /load_response_file\(mrb_state \*mrb, struct mrbc_args \*args, const char \*resp_path\);/
      if decl_pos
        line_end = content.index("\n", decl_pos)
        if line_end
          content.insert(line_end + 1, "\n/* Force linker to include load_response_file */\nint (*dummy_load_response_file)(mrb_state*, struct mrbc_args*, const char*) __attribute__((used)) = load_response_file;\n")
          modified = true
          puts "DEBUG: Added missing dummy_load_response_file variable"
        end
      end
    end

    # Ensure cleanup function handles response_argv (even if already patched)
    unless content.include?('if (args->response_argv)')
      # Replace original cleanup function lines with patched version
      if content.sub!(/  mrb_free\(mrb, \(void\*\)args->outfile\);\n  mrb_close\(mrb\);\n/, "  mrb_free(mrb, (void*)args->outfile);\n  if (args->response_argv) {\n    int i;\n    for (i = 0; i < args->response_argc; ++i) {\n      mrb_free(mrb, args->response_argv[i]);\n    }\n    mrb_free(mrb, args->response_argv);\n    args->response_argv = NULL;\n  }\n  /* Reference to keep load_response_file in binary */\n  if (0) load_response_file(NULL, NULL, NULL);\n  (void)load_response_file;\n  (void)dummy_load_response_file;\n  mrb_close(mrb);\n")
        modified = true
        puts "DEBUG: Patched cleanup function with response_argv handling"
      end
    end

    # Ensure load_file function handles @response files (even if already patched)
    unless content.include?('if (input[0] == \'@\')')
      # Add response file detection to load_file function
      if content.sub!(/  char \*input = args->argv\[args->idx\];\n/, "  char *input = args->argv[args->idx];\n  if (input[0] == '@') {\n    int rsp_status = load_response_file(mrb, args, input + 1);\n    if (rsp_status <= 0) {\n      if (rsp_status < 0) {\n        fprintf(stderr, \"%s: response file is empty. (%s)\\n\", args->prog, input);\n      }\n      else {\n        fprintf(stderr, \"%s: cannot open response file. (%s)\\n\", args->prog, input);\n      }\n      return mrb_nil_value();\n    }\n    input = args->argv[args->idx];\n  }\n")
        modified = true
        puts "DEBUG: Patched load_file function with @response detection"
      end
    end

    # Fix volatile warning in constructor if present
    content.sub!(/volatile static int \(\*ptr\)\(mrb_state\*, struct mrbc_args\*, const char\*\) = load_response_file;/, 'static int (*ptr)(mrb_state*, struct mrbc_args*, const char*) = load_response_file;')

    # Ensure load_response_file function definition exists (even if already patched)
    unless content.include?('#warning "load_response_file is being compiled"')
      partial_hook_start = content =~ /static\s+int\s*\r?\n\s*partial_hook/ ? $~.offset(0)[0] : nil
      if partial_hook_start
        load_response_func = <<~'C'.gsub(/^/, '')
int __attribute__((used, noinline))
load_response_file(mrb_state *mrb, struct mrbc_args *args, const char *resp_path)
{
  #warning "load_response_file is being compiled"
  FILE *f = fopen(resp_path, "r");
  if (!f) return 0;
  int count = 0;
  char line[1024];
  while (fgets(line, sizeof(line), f)) {
    char *p = strchr(line, '\n');
    if (p) *p = '\0';
    if (line[0] == '\0') continue;
    count++;
  }
  if (count == 0) {
    fclose(f);
    return -1;
  }
  rewind(f);
  char **lines = mrb_malloc(mrb, sizeof(char*) * count);
  int i = 0;
  while (fgets(line, sizeof(line), f)) {
    char *p = strchr(line, '\n');
    if (p) *p = '\0';
    if (line[0] == '\0') continue;
    lines[i] = mrb_malloc(mrb, strlen(line) + 1);
    strcpy(lines[i], line);
    i++;
  }
  fclose(f);
  args->response_argv = lines;
  args->response_argc = count;
  args->argv = lines;
  args->argc = count;
  args->idx = 0;
  return 1;
}
        C
        content.insert(partial_hook_start, load_response_func)
        modified = true
        puts "DEBUG: Added missing load_response_file function definition"
      end
    end

    # Function is now static, no need for attribute updates

    # Ensure stdio.h is included (required for FILE, fopen, fprintf, stderr)
    unless content.include?('#include <stdio.h>')
      # Insert after #include <string.h> line
      if content.sub!(/#include <string.h>\n/, "#include <string.h>\n#include <stdio.h>\n")
        modified = true
        puts "DEBUG: Added #include <stdio.h> to mrbc.c"
      end
    end



    if modified
      File.write(mrbc_patch_file, content)
    end
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
