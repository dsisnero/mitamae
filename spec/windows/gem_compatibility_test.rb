# mruby gem Windows compatibility test
# This recipe tests various mruby gems for Windows compatibility

if node[:platform] == 'windows'
  puts '=== mruby Gem Windows Compatibility Test ==='
  puts "Platform: #{node[:platform]}"
  puts "Platform version: #{node[:platform_version]}"
  puts ''

  # Test mruby-dir functionality
  puts 'Testing mruby-dir...'
  begin
    # Test Dir.pwd
    current_dir = Dir.pwd
    puts "  ✓ Dir.pwd works: #{current_dir}"

    # Test Dir.mkdir
    test_dir = 'C:\\mitamae_gem_test'
    begin
      Dir.mkdir(test_dir)
    rescue StandardError
      nil
    end
    if Dir.exist?(test_dir)
      puts '  ✓ Dir.mkdir works'
    else
      puts '  ✗ Dir.mkdir failed'
    end

    # Test Dir.exist?
    if Dir.exist?(test_dir)
      puts '  ✓ Dir.exist? works'
    else
      puts '  ✗ Dir.exist? failed'
    end

    # Test Dir.glob (requires mruby-dir-glob)
    begin
      files = Dir.glob('C:\\Windows\\*.exe').first(3)
      puts "  ✓ Dir.glob works (found #{files.size} files)"
    rescue StandardError => e
      puts "  ✗ Dir.glob failed: #{e.message}"
    end

    # Clean up
    begin
      Dir.rmdir(test_dir)
    rescue StandardError
      nil
    end
  rescue StandardError => e
    puts "  ✗ mruby-dir test failed: #{e.message}"
    puts "  Backtrace: #{e.backtrace.first(3).join(', ')}"
  end

  puts ''

  # Test mruby-file-stat functionality
  puts 'Testing mruby-file-stat...'
  begin
    require 'file/stat'

    # Test File.stat
    begin
      stat = begin
        File.stat('C:\\Windows\\notepad.exe')
      rescue StandardError
        File.stat('C:\\Windows\\System32\\notepad.exe')
      end
    rescue StandardError
      nil
    end
    if stat
      puts '  ✓ File.stat works'
      puts "    Size: #{stat.size}" if stat.respond_to?(:size)
      puts "    Mtime: #{stat.mtime}" if stat.respond_to?(:mtime)
    else
      # Try a different file
      stat = begin
        File.stat('C:\\Windows\\win.ini')
      rescue StandardError
        nil
      end
      if stat
        puts '  ✓ File.stat works (win.ini)'
      else
        puts '  ✗ File.stat failed for all test files'
      end
    end

    # Test File.exist?
    if File.exist?('C:\\Windows')
      puts '  ✓ File.exist? works for directories'
    else
      puts '  ✗ File.exist? failed for directories'
    end

    if File.exist?('C:\\Windows\\notepad.exe') || File.exist?('C:\\Windows\\System32\\notepad.exe')
      puts '  ✓ File.exist? works for files'
    else
      puts '  ✗ File.exist? failed for files'
    end
  rescue StandardError => e
    puts "  ✗ mruby-file-stat test failed: #{e.message}"
    puts "  Backtrace: #{e.backtrace.first(3).join(', ')}"
  end

  puts ''

  # Test mruby-etc functionality
  puts 'Testing mruby-etc...'
  begin
    require 'etc'

    # Test Etc.getpwuid
    begin
      pw = Etc.getpwuid(0) # Usually root/Administrator
      if pw
        puts '  ✓ Etc.getpwuid works'
        puts "    Name: #{pw.name}" if pw.respond_to?(:name)
      else
        puts '  ⚠ Etc.getpwuid returned nil (might be expected on Windows)'
      end
    rescue StandardError => e
      puts "  ⚠ Etc.getpwuid failed: #{e.message} (might be expected on Windows)"
    end

    # Test Etc.getlogin
    begin
      login = Etc.getlogin
      if login
        puts "  ✓ Etc.getlogin works: #{login}"
      else
        puts '  ⚠ Etc.getlogin returned nil'
      end
    rescue StandardError => e
      puts "  ✗ Etc.getlogin failed: #{e.message}"
    end
  rescue LoadError
    puts '  ✗ mruby-etc not loaded'
  rescue StandardError => e
    puts "  ✗ mruby-etc test failed: #{e.message}"
  end

  puts ''

  # Test mruby-env functionality
  puts 'Testing mruby-env...'
  begin
    require 'env'

    # Test ENV access
    path = ENV.fetch('PATH', nil)
    if path && path.length > 0
      puts "  ✓ ENV['PATH'] works (length: #{path.length})"
    else
      puts "  ✗ ENV['PATH'] failed"
    end

    # Test ENV[] with Windows-specific variable
    temp = ENV['TEMP'] || ENV.fetch('TMP', nil)
    if temp
      puts "  ✓ ENV['TEMP/TMP'] works: #{temp}"
    else
      puts "  ✗ ENV['TEMP/TMP'] failed"
    end

    # Test ENV[] with case sensitivity
    path1 = ENV.fetch('Path', nil)
    path2 = ENV.fetch('PATH', nil)
    if path1 == path2
      puts '  ✓ ENV is case-insensitive (Windows behavior)'
    else
      puts '  ⚠ ENV might be case-sensitive (unexpected on Windows)'
    end
  rescue LoadError
    puts '  ✗ mruby-env not loaded'
  rescue StandardError => e
    puts "  ✗ mruby-env test failed: #{e.message}"
  end

  puts ''

  # Test path handling
  puts 'Testing path handling...'
  begin
    # Test forward vs backslash
    forward_path = 'C:/Windows/System32'
    backslash_path = 'C:\\Windows\\System32'

    # Check if both paths work
    forward_exists = begin
      Dir.exist?(forward_path)
    rescue StandardError
      false
    end
    backslash_exists = begin
      Dir.exist?(backslash_path)
    rescue StandardError
      false
    end

    if forward_exists && backslash_exists
      puts '  ✓ Both forward and backslash paths work'
    elsif backslash_exists
      puts "  ✓ Backslash paths work, forward slashes: #{forward_exists ? 'yes' : 'no'}"
    else
      puts '  ✗ Path testing failed'
    end

    # Test drive letters
    if Dir.exist?('C:\\')
      puts '  ✓ Drive letter paths work'
    else
      puts '  ✗ Drive letter paths failed'
    end

    # Test relative paths
    begin
      Dir.mkdir('test_rel_dir')
    rescue StandardError
      nil
    end
    if Dir.exist?('test_rel_dir')
      puts '  ✓ Relative paths work'
      Dir.rmdir('test_rel_dir')
    else
      puts '  ✗ Relative paths failed'
    end
  rescue StandardError => e
    puts "  ✗ Path handling test failed: #{e.message}"
  end

  puts ''
  puts '=== Compatibility Test Complete ==='

else
  puts 'Not running on Windows, skipping Windows compatibility tests'
  puts "Platform: #{node[:platform]}"
end
