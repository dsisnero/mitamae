# Windows-specific build tasks
namespace :windows do
  desc "Build and test mitamae for Windows"
  task :test do
    ENV['OS'] = 'Windows_NT' unless ENV['OS']
    sh "rake compile BUILD_TARGET=windows-x86_64"
  end

  desc "Build mitamae for Windows"
  task :build do
    ENV['OS'] = 'Windows_NT' unless ENV['OS']
    sh "rake compile BUILD_TARGET=windows-x86_64"
    # Add any Windows-specific post-build steps here
  end
end
