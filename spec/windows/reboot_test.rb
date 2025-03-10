# Test reboot notification
execute 'Trigger reboot check' do
  command 'echo "Pending reboot test"'
  notifies :request_reboot, 'reboot[mitamae-test]'
end

reboot 'mitamae-test' do
  action :nothing
  reason 'Mitamae Windows Test Reboot'
end
