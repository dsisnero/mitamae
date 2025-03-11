# Test winget-specific package management
package 'Microsoft.VisualStudioCode' do
  action :install
  provider :winget
  not_if { ENV['CONTAINER'] == 'true' || ENV['DOCKER_WINDOWS_CONTAINER'] == '1' }
  not_if { !check_command('where winget') }
end

package 'Git.Git' do
  action :install
  provider :winget
  not_if { ENV['CONTAINER'] == 'true' || ENV['DOCKER_WINDOWS_CONTAINER'] == '1' }
  not_if { !check_command('where winget') }
end

# Fallback tests for container environment
package 'vscode' do
  action :install
  provider :chocolatey
  only_if { ENV['CONTAINER'] == 'true' || ENV['DOCKER_WINDOWS_CONTAINER'] == '1' }
  only_if { check_command('where choco') }
end

package 'git' do
  action :install
  provider :chocolatey
  only_if { ENV['CONTAINER'] == 'true' || ENV['DOCKER_WINDOWS_CONTAINER'] == '1' }
  only_if { check_command('where choco') }
end
