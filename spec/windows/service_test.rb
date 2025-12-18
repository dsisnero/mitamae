# Windows service test recipe
# Note: Some actions require administrator privileges

if node[:platform] == 'windows'
  # Test service status check (should work without admin)
  service 'W32Time' do
    action :nothing
  end

  # Test starting a service (requires admin if service is stopped)
  # service 'W32Time' do
  #   action :start
  # end

  # Test stopping a service (requires admin)
  # service 'W32Time' do
  #   action :stop
  # end

  # Test restarting a service (requires admin)
  # service 'W32Time' do
  #   action :restart
  # end

  # Test enabling a service (requires admin)
  # service 'W32Time' do
  #   action :enable
  # end

  # Test disabling a service (requires admin)
  # service 'W32Time' do
  #   action :disable
  # end

  # Test with a non-existent service (should fail gracefully)
  service 'NonExistentServiceName' do
    action :nothing
  end

  # Log service information
  puts '=== Windows Service Test ==='
  puts "Platform: #{node[:platform]}"
  puts 'Testing W32Time service...'

  # Check service status using sc command
  result = run_command('sc query W32Time', error: false)
  if result.exit_status == 0
    puts 'W32Time service exists'
    puts "Output: #{result.stdout.lines.first(3).join}"
  else
    puts 'W32Time service query failed (might not exist or no permissions)'
  end
end
