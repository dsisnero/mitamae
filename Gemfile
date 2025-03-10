source 'https://rubygems.org'

# Cross-platform core dependencies
gem 'rake', '~> 13.0'
gem 'rspec', '~> 3.10'
gem 'serverspec', '~> 2.41'
gem 'docker-api'

# Windows-specific dependencies
platform :mswin, :mingw do
  gem 'winrm', '~> 2.3'
  gem 'winrm-fs', '~> 1.3'
  gem 'rubyzip', '>= 2.3.2'
  gem 'os', '>= 1.1.4'
end

# Linux/Mac development tools
platform :ruby do
  gem 'pry'
  gem 'rb-readline'
end

# Pinned Bundler version compatible with all platforms
gem 'bundler', '~> 2.4.22'
