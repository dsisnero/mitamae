# Test Windows environment variables
env 'MITAMAE_TEST_VAR' do
  value 'test_value'
  action :create
end

execute 'Verify environment variable' do
  command 'echo %MITAMAE_TEST_VAR%'
end
