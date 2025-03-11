MRuby::Gem::Specification.new('mruby-yaml') do |spec|
  spec.license = 'MIT'
  spec.authors = 'Andrew Nordman', 'Takeshi Watanabe'
  spec.summary = 'LibYAML binding for mruby'
  spec.version = '0.1.0'

  spec.linker.libraries << 'yaml'
  
  # Windows-compatible build process
  if ENV['OS'] == 'Windows_NT'
    # Windows-specific build instructions
    spec.cc.include_paths << "#{build.root}/src"
    
    # Use pre-built libyaml for Windows
    spec.linker.library_paths << "#{build.root}/build/libyaml/lib"
    spec.cc.include_paths << "#{build.root}/build/libyaml/include"
    
    # Skip the bootstrap script that doesn't work on Windows
    spec.build.defines << 'MRUBY_YAML_WINDOWS_BUILD'
  else
    # Original Unix build process
    yaml_dir = "#{spec.dir}/yaml"
    
    # Define compiling options
    spec.cc.include_paths << "#{yaml_dir}/include"
    spec.cc.flags << "-DHAVE_CONFIG_H"
    
    # Compile libyaml
    spec.build do
      Dir.chdir(yaml_dir) do
        if !File.exist?('configure')
          sh './bootstrap'
        end
        if !File.exist?('Makefile')
          sh './configure'
        end
        sh 'make'
      end
    end
  end
end
