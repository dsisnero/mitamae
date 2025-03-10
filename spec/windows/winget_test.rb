# Test winget-specific package management
package 'Microsoft.VisualStudioCode' do
  action :install
  provider :winget
end

package 'Git.Git' do
  action :install
  provider :winget
end
