# Test chocolatey-specific package management
package 'git' do
  action :install
  provider :chocolatey
end

package '7zip' do
  action :install
  provider :chocolatey
end
