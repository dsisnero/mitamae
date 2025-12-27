#!/usr/bin/env ruby
require "open3"
require "tmpdir"

ROOT = File.expand_path(__dir__)

def resolve_mrbc
  return ENV["MRBC"] if ENV["MRBC"]

  mrbc = File.join(ROOT, "mruby", "build", "host", "bin", "mrbc")
  if Gem.win_platform? && !File.exist?(mrbc) && File.exist?("#{mrbc}.exe")
    mrbc = "#{mrbc}.exe"
  end
  mrbc
end

def run_mrbc(mrbc, args, label)
  stdout, stderr, status = Open3.capture3(mrbc, *args)
  return if status.success?

  warn stdout unless stdout.empty?
  warn stderr unless stderr.empty?
  abort "mrbc failed for #{label}"
end

def run_mrbc_expect_failure(mrbc, args, label, expected_stderr)
  stdout, stderr, status = Open3.capture3(mrbc, *args)
  if status.success?
    abort "mrbc unexpectedly succeeded for #{label}"
  end
  if expected_stderr && !stderr.include?(expected_stderr)
    warn stdout unless stdout.empty?
    warn stderr unless stderr.empty?
    abort "mrbc stderr did not include #{expected_stderr.inspect} for #{label}"
  end
end

mrbc = resolve_mrbc
unless File.exist?(mrbc)
  warn "mrbc not found at #{mrbc}"
  warn "Build it with: cd mruby && rake"
  warn "Or set MRBC to the mrbc path."
  exit 1
end

Dir.mktmpdir("mrbc-response") do |dir|
  files = []
  200.times do |i|
    name = (i == 149) ? "file with spaces #{i}.rb" : "file#{i}.rb"
    path = File.join(dir, name)
    File.write(path, "VALUE_#{i} = #{i}\n")
    files << path
  end

  rsp = File.join(dir, "files.rsp")
  File.open(rsp, "w") { |f| files.each { |path| f.puts path } }

  puts "Testing response file with #{files.size} inputs..."
  response_out = File.join(dir, "response_out.c")
  run_mrbc(mrbc, ["-Btest_func", "-o", response_out, "@#{rsp}"], "response file")
  abort "response output not created" unless File.exist?(response_out)

  puts "Testing empty response file failure..."
  empty_rsp = File.join(dir, "empty.rsp")
  File.write(empty_rsp, "")
  empty_out = File.join(dir, "empty_out.c")
  run_mrbc_expect_failure(
    mrbc,
    ["-Btest_func", "-o", empty_out, "@#{empty_rsp}"],
    "empty response file",
    "response file is empty"
  )
  abort "empty response output should not be created" if File.exist?(empty_out)

  if Gem.win_platform?
    rsp_win = File.join(dir, "files_windows.rsp")
    File.open(rsp_win, "w") do |f|
      files.each { |path| f.puts path.tr("/", "\\") }
    end

    puts "Testing response file with Windows paths..."
    response_out_win = File.join(dir, "response_out_win.c")
    run_mrbc(mrbc, ["-Btest_func", "-o", response_out_win, "@#{rsp_win}"], "response file windows paths")
    abort "windows response output not created" unless File.exist?(response_out_win)
  end

  puts "Testing direct args with 50 inputs..."
  direct_out = File.join(dir, "direct_out.c")
  run_mrbc(mrbc, ["-Btest_func", "-o", direct_out] + files.take(50), "direct args")
  abort "direct output not created" unless File.exist?(direct_out)
end

puts "OK: response file and direct args succeeded."
