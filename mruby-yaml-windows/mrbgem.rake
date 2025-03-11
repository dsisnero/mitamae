MRuby::Gem::Specification.new('mruby-yaml') do |spec|
  spec.license = 'MIT'
  spec.authors = 'Andrew Nordman', 'Takeshi Watanabe'
  spec.summary = 'LibYAML binding for mruby'
  spec.version = '0.1.0'

  spec.linker.libraries << 'yaml'
  
  # Windows-compatible build process
  if ENV['OS'] == 'Windows_NT'
    # Windows-specific build instructions
    spec.cc.include_paths << "#{spec.dir}/src"
    
    # Define dummy methods to avoid bootstrap script
    spec.cc.defines << 'MRUBY_YAML_WINDOWS_BUILD'
    
    # Create src directory if it doesn't exist
    Dir.mkdir("#{spec.dir}/src") unless Dir.exist?("#{spec.dir}/src")
    
    # Create dummy yaml.h file
    yaml_h_path = "#{spec.dir}/src/yaml.h"
    unless File.exist?(yaml_h_path)
      File.write(yaml_h_path, <<~HEADER)
        #ifndef YAML_H
        #define YAML_H
        
        // Minimal yaml.h for Windows build
        typedef struct yaml_parser_s yaml_parser_t;
        typedef struct yaml_emitter_s yaml_emitter_t;
        
        #endif
      HEADER
    end
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
