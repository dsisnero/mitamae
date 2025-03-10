# Windows package test recipe

# Test Chocolatey package installation
package 'git' do
  action :install
end

# Test package removal
package 'git' do
  action :remove
end

# Test package installation with version
package 'notepad++' do
  version '8.4.7'
  action :install
end

# Test package installation with options
package 'curl' do
  options '--force'
  action :install
end

# Test package installation status check
package 'notepad++' do
  action :install
  only_if 'where notepad++'
end

# Test package removal with not_if
package 'curl' do
  action :remove
  not_if 'where nonexistentprogram'
end
