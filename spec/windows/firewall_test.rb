# Test Windows firewall rules
execute 'Create firewall rule' do
  command 'New-NetFirewallRule -DisplayName "MitamaeTest" -Direction Inbound -Action Allow'
  not_if 'Get-NetFirewallRule -DisplayName "MitamaeTest"'
end
