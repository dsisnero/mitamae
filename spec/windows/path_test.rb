# Test Windows PATH management
env 'PATH' do
  action :append
  value 'C:\\mitamae-test-path'
  delimiter ';'
end

execute 'Verify PATH update' do
  command 'echo %PATH% | find "C:\\mitamae-test-path"'
end
