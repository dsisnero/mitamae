# Test PowerShell execution policy
execute 'Set Execution Policy' do
  command 'Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force'
  not_if '(Get-ExecutionPolicy) -eq "RemoteSigned"'
end
