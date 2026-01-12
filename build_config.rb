# frozen_string_literal: true

def disabled_gems
  @disabled_gems ||= ENV.fetch('MITAMAE_DISABLE_GEMS', '').split(',').map(&:strip).reject(&:empty?)
end

def gem_disabled?(name)
  disabled_gems.include?(name)
end

def apply_disabled_gems_dependency_filter
  return if disabled_gems.empty?

  return if MRuby::Gem::Specification.method_defined?(:add_dependency_without_mitamae_disable)

  MRuby::Gem::Specification.class_eval do
    alias_method :add_dependency_without_mitamae_disable, :add_dependency

    def add_dependency(name, *requirements)
      disabled = ENV.fetch('MITAMAE_DISABLE_GEMS', '').split(',').map(&:strip).reject(&:empty?)
      if disabled.include?(name)
        if ENV['MITAMAE_GEM_DEBUG'] && !ENV['MITAMAE_GEM_DEBUG'].empty?
          $stderr.puts "MITAMAE_GEM_DEBUG: skipping dependency #{name} for #{self.name}"
        end
        return
      end
      add_dependency_without_mitamae_disable(name, *requirements)
    end
  end
end

def gem_config(conf)
  apply_disabled_gems_dependency_filter
  conf.gem __dir__
  if conf.respond_to?(:gems) && conf.gems.respond_to?(:delete_if)
    conf.gems.delete_if { |g| g.name == 'mruby-onig-regexp' }
    if disabled_gems.any?
      conf.gems.delete_if { |g| disabled_gems.include?(g.name) }
    end
  end
end

def windows_safe_cflags(conf)
  [conf.cc, conf.linker].each do |cc|
    cc.flags << '-fno-strict-aliasing'
    cc.flags << '-fno-omit-frame-pointer'
  end
  conf.cc.flags << '-O0'
end

def debug_config(conf)
  conf.instance_eval do
    # In `enable_debug`, use this for release build too.
    # Allow showing backtrace and prevent "fptr_finalize failed" error in mruby-io.
    @mrbc.compile_options += ' -g'
  end
end

def debug_symbols_config(conf)
  return unless ENV['MITAMAE_DEBUG_SYMBOLS'] && !ENV['MITAMAE_DEBUG_SYMBOLS'].empty?

  conf.cc.flags << '-g'
  conf.cc.flags << '-gcodeview'
  conf.linker.flags << '-g'
  conf.linker.flags << '-gcodeview'
end

def download_macos_sdk(path)
  version = '11.3'
  system('wget', "https://github.com/phracker/MacOSX-SDKs/releases/download/#{version}/MacOSX#{version}.sdk.tar.xz",
         exception: true)
  system('tar', 'xf', "MacOSX#{version}.sdk.tar.xz", exception: true)
  system('rm', "MacOSX#{version}.sdk.tar.xz", exception: true)
  system('mv', "MacOSX#{version}.sdk", path, exception: true)
end

macos_sdk = File.expand_path('./MacOSX.sdk', __dir__)
build_targets = ENV.fetch('BUILD_TARGET', '').split(',')

# mruby's build system always requires to run host build for mrbc
MRuby::Build.new do |conf|
  toolchain :gcc

  # conf.enable_bintest
  # conf.enable_debug
  # conf.enable_test
  if ENV['MRUBY_YAML_USE_SYSTEM_LIBRARY'] && !ENV['MRUBY_YAML_USE_SYSTEM_LIBRARY'].empty? &&
     !gem_disabled?('mruby-yaml')
    vcpkg_root = ENV.fetch('VCPKG_ROOT', 'C:/vcpkg')
    default_triplet = build_targets.include?('windows-i386') ? 'x86-windows' : 'x64-windows'
    triplet = ENV.fetch('VCPKG_TRIPLET', default_triplet)
    conf.cc.include_paths << "#{vcpkg_root}/installed/#{triplet}/include"
    conf.linker.library_paths << "#{vcpkg_root}/installed/#{triplet}/lib"
    conf.linker.libraries << 'yaml'
    conf.cc.flags << '-DYAML_DECLARE_STATIC' if triplet.end_with?('-static')
  end
  if build_targets.include?('windows-i386') && !build_targets.include?('windows-x86_64')
    [conf.cc, conf.linker].each do |cc|
      cc.command = 'zig cc -target i386-windows-gnu -static'
      cc.flags << '-DMRB_ARY_LENGTH_MAX=65536'
    end
    conf.archiver.command = 'zig ar'
  end

  debug_config(conf)
  debug_symbols_config(conf)
  gem_config(conf)
  # Function is now static, no need for undefined reference flag
end

if build_targets.include?('linux-x86_64')
  MRuby::Build.new('linux-x86_64') do |conf|
    toolchain :gcc

    [conf.cc, conf.linker].each do |cc|
      cc.command = 'zig cc -target x86_64-linux-musl'
    end
    conf.archiver.command = 'zig ar'

    debug_config(conf)
    debug_symbols_config(conf)
    gem_config(conf)
  end
end

if build_targets.include?('linux-i386')
  MRuby::CrossBuild.new('linux-i386') do |conf|
    toolchain :gcc

    [conf.cc, conf.linker].each do |cc|
      cc.command = 'zig cc -target i386-linux-musl'
    end
    conf.archiver.command = 'zig ar'

    # To configure: mrbgems/mruby-yaml, k0kubun/mruby-onig-regexp
    conf.host_target = 'i386-pc-linux-gnu'

    debug_config(conf)
    debug_symbols_config(conf)
    gem_config(conf)
  end
end

if build_targets.include?('linux-armhf')
  MRuby::CrossBuild.new('linux-armhf') do |conf|
    toolchain :gcc

    [conf.cc, conf.linker].each do |cc|
      cc.command = 'zig cc -target arm-linux-musleabihf'
    end
    conf.archiver.command = 'zig ar'

    # To configure: mrbgems/mruby-yaml, k0kubun/mruby-onig-regexp
    conf.host_target = 'arm-linux-musleabihf'

    debug_config(conf)
    debug_symbols_config(conf)
    gem_config(conf)
  end
end

if build_targets.include?('linux-aarch64')
  MRuby::CrossBuild.new('linux-aarch64') do |conf|
    toolchain :gcc

    [conf.cc, conf.linker].each do |cc|
      cc.command = 'zig cc -target aarch64-linux-musl'
    end
    conf.archiver.command = 'zig ar'

    # To configure: mrbgems/mruby-yaml, k0kubun/mruby-onig-regexp
    conf.host_target = 'aarch64-linux-musl'

    debug_config(conf)
    debug_symbols_config(conf)
    gem_config(conf)
  end
end

if build_targets.include?('darwin-x86_64')
  MRuby::CrossBuild.new('darwin-x86_64') do |conf|
    toolchain :gcc

    unless Dir.exist?(macos_sdk)
      download_macos_sdk(macos_sdk)
    end

    conf.cc.command = "zig cc -target x86_64-macos -mmacosx-version-min=10.14 -isysroot #{macos_sdk.shellescape} -iwithsysroot /usr/include -iframeworkwithsysroot /System/Library/Frameworks"
    conf.linker.command = "zig cc -target x86_64-macos -mmacosx-version-min=10.4 --sysroot #{macos_sdk.shellescape} -F/System/Library/Frameworks -L/usr/lib"
    conf.archiver.command = 'zig ar'
    ENV['RANLIB'] ||= 'zig ranlib'

    # To configure: mrbgems/mruby-yaml, k0kubun/mruby-onig-regexp
    conf.host_target = 'x86_64-darwin'

    debug_config(conf)
    debug_symbols_config(conf)
    gem_config(conf)
  end
end

if build_targets.include?('darwin-aarch64')
  MRuby::CrossBuild.new('darwin-aarch64') do |conf|
    toolchain :gcc

    unless Dir.exist?(macos_sdk)
      download_macos_sdk(macos_sdk)
    end

    conf.cc.command = "zig cc -target aarch64-macos -mmacosx-version-min=11.1 -isysroot #{macos_sdk.shellescape} -iwithsysroot /usr/include -iframeworkwithsysroot /System/Library/Frameworks"
    conf.linker.command = "zig cc -target aarch64-macos -mmacosx-version-min=11.1 --sysroot #{macos_sdk.shellescape} -F/System/Library/Frameworks -L/usr/lib"
    conf.archiver.command = 'zig ar'
    ENV['RANLIB'] ||= 'zig ranlib'

    # To configure: mrbgems/mruby-yaml, k0kubun/mruby-onig-regexp
    conf.host_target = 'aarch64-darwin'

    debug_config(conf)
    debug_symbols_config(conf)
    gem_config(conf)
  end
end

if build_targets.include?('windows-x86_64')
  MRuby::CrossBuild.new('windows-x86_64') do |conf|
    toolchain :gcc

    [conf.cc, conf.linker].each do |cc|
      cc.command = 'zig cc -target x86_64-windows-gnu -static'
      cc.flags << '-DMRB_ARY_LENGTH_MAX=65536'
    end
    conf.archiver.command = 'zig ar'

    # Windows-specific configuration
    conf.cc.flags << '-DMRB_NO_DIRECT_THREADING'
    conf.disable_libmrgss if conf.respond_to?(:disable_libmrgss)
    conf.disable_presym if conf.respond_to?(:disable_presym)
    windows_safe_cflags(conf)

    # To configure: mrbgems/mruby-yaml, k0kubun/mruby-onig-regexp
    conf.host_target = 'x86_64-w64-mingw32'

    if ENV['MRUBY_YAML_USE_SYSTEM_LIBRARY'] && !ENV['MRUBY_YAML_USE_SYSTEM_LIBRARY'].empty?
      vcpkg_root = ENV.fetch('VCPKG_ROOT', 'C:/vcpkg')
      triplet = ENV.fetch('VCPKG_TRIPLET', 'x64-windows')
      conf.cc.include_paths << "#{vcpkg_root}/installed/#{triplet}/include"
      conf.linker.library_paths << "#{vcpkg_root}/installed/#{triplet}/lib"
      conf.linker.libraries << 'yaml' unless gem_disabled?('mruby-yaml')
      conf.cc.flags << '-DYAML_DECLARE_STATIC' if triplet.end_with?('-static')
    end
    if ENV['ONIGURUMA_PREFIX'] && !ENV['ONIGURUMA_PREFIX'].empty?
      conf.cc.include_paths << "#{ENV['ONIGURUMA_PREFIX']}/include"
      conf.linker.library_paths << "#{ENV['ONIGURUMA_PREFIX']}/lib"
    end

    debug_config(conf)
    gem_config(conf)
  end
end

if build_targets.include?('windows-i386')
  MRuby::CrossBuild.new('windows-i386') do |conf|
    toolchain :gcc

    [conf.cc, conf.linker].each do |cc|
      cc.command = 'zig cc -target i386-windows-gnu -static'
      cc.flags << '-DMRB_ARY_LENGTH_MAX=65536'
    end
    conf.archiver.command = 'zig ar'

    # Windows-specific configuration
    conf.disable_libmrgss if conf.respond_to?(:disable_libmrgss)
    conf.disable_presym if conf.respond_to?(:disable_presym)
    windows_safe_cflags(conf)

    # To configure: mrbgems/mruby-yaml, k0kubun/mruby-onig-regexp
    conf.host_target = 'i686-w64-mingw32'

    if ENV['MRUBY_YAML_USE_SYSTEM_LIBRARY'] && !ENV['MRUBY_YAML_USE_SYSTEM_LIBRARY'].empty?
      vcpkg_root = ENV.fetch('VCPKG_ROOT', 'C:/vcpkg')
      triplet = ENV.fetch('VCPKG_TRIPLET', 'x86-windows')
      conf.cc.include_paths << "#{vcpkg_root}/installed/#{triplet}/include"
      conf.linker.library_paths << "#{vcpkg_root}/installed/#{triplet}/lib"
      conf.linker.libraries << 'yaml' unless gem_disabled?('mruby-yaml')
      conf.cc.flags << '-DYAML_DECLARE_STATIC' if triplet.end_with?('-static')
    end
    if ENV['ONIGURUMA_PREFIX'] && !ENV['ONIGURUMA_PREFIX'].empty?
      conf.cc.include_paths << "#{ENV['ONIGURUMA_PREFIX']}/include"
      conf.linker.library_paths << "#{ENV['ONIGURUMA_PREFIX']}/lib"
    end

    debug_config(conf)
    gem_config(conf)
  end
end
