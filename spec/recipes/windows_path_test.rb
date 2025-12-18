# Test Windows path compatibility
# This recipe tests the WindowsPath module functionality

# Test basic path normalization
file '/tmp/windows_path_test' do
  content <<~CONTENT
    Platform: #{node[:platform]}
    File.join test: #{File.join('C:', 'Users', 'test', 'file.txt')}
    Dir.pwd: #{Dir.pwd}
    WindowsPath.windows?: #{defined?(MItamae::WindowsPath) && MItamae::WindowsPath.windows?}
  CONTENT
end

# Test path joining with different separators
if defined?(MItamae::WindowsPath) && MItamae::WindowsPath.windows?
  file '/tmp/windows_path_join_test' do
    content <<~CONTENT
      Join forward slashes: #{MItamae::WindowsPath.join('C:/Users', 'test/file.txt')}
      Join backslashes: #{MItamae::WindowsPath.join('C:\\Users', 'test\\file.txt')}
      Join mixed: #{MItamae::WindowsPath.join('C:/Users', 'test\\file.txt')}
      Normalize forward: #{MItamae::WindowsPath.normalize('C:/Users/test/file.txt')}
      Normalize backslash: #{MItamae::WindowsPath.normalize('C:\\Users\\test\\file.txt')}
      Absolute? C:\\path: #{MItamae::WindowsPath.absolute?('C:\\path')}
      Absolute? /path: #{MItamae::WindowsPath.absolute?('/path')}
      Absolute? relative/path: #{MItamae::WindowsPath.absolute?('relative/path')}
    CONTENT
  end

  # Test UNC paths
  file '/tmp/windows_unc_test' do
    content <<~CONTENT
      UNC path absolute?: #{MItamae::WindowsPath.absolute?('\\\\server\\share\\path')}
      Normalize UNC: #{MItamae::WindowsPath.normalize('\\\\server\\share\\path\\file.txt')}
    CONTENT
  end
end
