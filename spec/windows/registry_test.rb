# Test Windows registry management
registry_key 'HKCU\Software\MitamaeTest' do
  action :create
end

registry_value 'HKCU\Software\MitamaeTest\TestValue' do
  type :dword
  data 1
end
