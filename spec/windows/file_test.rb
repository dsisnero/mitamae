# Test Windows file attributes
directory 'C:\mitamae-test' do
  action :create
end

file 'C:\mitamae-test\hidden.txt' do
  content 'hidden file'
  hidden true
end

file 'C:\mitamae-test\readonly.txt' do
  content 'readonly file'
  readonly true
end
