# Windows package test recipe

# Test Chocolatey package installation
package 'git' do
  provider :chocolatey
  action :install
end

# Test package removal
package 'git' do
  provider :chocolatey
  action :remove
end

# Test package installation with version
package 'notepad++' do
  provider :chocolatey
  version '8.4.7'
  action :install
end

# Test package installation with options
package 'curl' do
  provider :chocolatey
  options '--force'
  action :install
end

# Test WinGet provider explicitly (skipped in container)
package 'Microsoft.PowerToys' do
  provider :winget
  action :install
  not_if { ENV['CONTAINER'] == 'true' || ENV['DOCKER_WINDOWS_CONTAINER'] == '1' }
  not_if { !check_command('where winget') }
end

# Test package installation status check
package 'notepad++' do
  provider :chocolatey
  action :install
  only_if 'where notepad++'
end

# Test package removal with not_if
package 'curl' do
  provider :chocolatey
  action :remove
  not_if 'where nonexistentprogram'
end
