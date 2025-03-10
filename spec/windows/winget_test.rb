# Test winget-specific package management
package 'Microsoft.VisualStudioCode' do
  action :install
  provider :winget
  not_if { ENV['CONTAINER'] == 'true' }
end

package 'Git.Git' do
  action :install
  provider :winget
  not_if { ENV['CONTAINER'] == 'true' }
end

# Fallback tests for container environment
package 'vscode' do
  action :install
  provider :chocolatey
  only_if { ENV['CONTAINER'] == 'true' }
end

package 'git' do
  action :install
  provider :chocolatey
  only_if { ENV['CONTAINER'] == 'true' }
end
