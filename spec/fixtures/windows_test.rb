# Windows test recipe

# Test execute resource
execute 'echo Hello from Windows' do
  command 'cmd /c echo Hello from Windows'
end

# Test directory resource
directory 'C:\mitamae_test' do
  action :create
end

# Test file resource
file 'C:\mitamae_test\test.txt' do
  content 'This is a test file created by mitamae'
end

# Test environment variable
execute 'test environment variable' do
  command 'cmd /c echo %TEMP%'
end

# Test command output
result = run_command('cmd /c echo Command output test', error: false)
puts "Command exit status: #{result.exit_status}"
puts "Command stdout: #{result.stdout}"

# Test Windows-specific attributes
puts "Platform: #{node[:platform]}"
puts "Platform version: #{node[:platform_version]}"
