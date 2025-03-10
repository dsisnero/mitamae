# Test Windows service management
service 'WinRM' do
  action [:enable, :start]
end

execute 'Verify WinRM service' do
  command 'sc query WinRM | find "RUNNING"'
end
