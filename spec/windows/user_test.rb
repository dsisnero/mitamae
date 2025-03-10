# Test local user management
user 'mitamae-test-user' do
  action :create
  password 'P@ssw0rd!'
end

group 'Administrators' do
  action :modify
  members ['mitamae-test-user']
  append true
end
