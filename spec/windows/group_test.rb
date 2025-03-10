# Test Windows group management
group 'mitamae-test-group' do
  action :create
end

execute 'Verify group creation' do
  command 'Get-LocalGroup -Name mitamae-test-group'
end
