MRuby::Gem::Specification.new('mitamae') do |spec|
  spec.license = 'MIT'
  spec.author  = [
    'Takashi Kokubun',
    'Ryota Arai',
  ]
  spec.summary = 'mitamae'
  spec.bins    = ['mitamae']

  disabled_gems = ENV.fetch('MITAMAE_DISABLE_GEMS', '').split(',').map(&:strip).reject(&:empty?)
  if ENV['MITAMAE_GEM_DEBUG'] && !ENV['MITAMAE_GEM_DEBUG'].empty?
    $stderr.puts "MITAMAE_GEM_DEBUG: disabled_gems=#{disabled_gems.join(',')}"
  end
  add_dep = lambda do |name, **opts|
    if disabled_gems.include?(name)
      if ENV['MITAMAE_GEM_DEBUG'] && !ENV['MITAMAE_GEM_DEBUG'].empty?
        $stderr.puts "MITAMAE_GEM_DEBUG: skipping #{name}"
      end
      return
    end

    if ENV['MITAMAE_GEM_DEBUG'] && !ENV['MITAMAE_GEM_DEBUG'].empty?
      $stderr.puts "MITAMAE_GEM_DEBUG: adding #{name}"
    end
    spec.add_dependency name, **opts
  end

  add_dep.call 'mruby-enum-ext',    core: 'mruby-enum-ext'
  add_dep.call 'mruby-enumerator',  core: 'mruby-enumerator'
  add_dep.call 'mruby-eval',        core: 'mruby-eval'
  add_dep.call 'mruby-exit',        core: 'mruby-exit'
  add_dep.call 'mruby-hash-ext',    core: 'mruby-hash-ext'
  add_dep.call 'mruby-io',          core: 'mruby-io'
  add_dep.call 'mruby-kernel-ext',  core: 'mruby-kernel-ext'
  add_dep.call 'mruby-object-ext',  core: 'mruby-object-ext'
  add_dep.call 'mruby-sprintf',     core: 'mruby-sprintf'
  add_dep.call 'mruby-struct',      core: 'mruby-struct'
  add_dep.call 'mruby-symbol-ext',  core: 'mruby-symbol-ext'

  add_dep.call 'mruby-at_exit',     github: 'ksss/mruby-at_exit', branch: 'master'
  add_dep.call 'mruby-dir',         mgem: 'mruby-dir'
  add_dep.call 'mruby-dir-glob',    mgem: 'mruby-dir-glob'
  add_dep.call 'mruby-env',         mgem: 'mruby-env'
  add_dep.call 'mruby-file-stat',   mgem: 'mruby-file-stat'
  add_dep.call 'mruby-hashie',      mgem: 'mruby-hashie'
  add_dep.call 'mruby-json',        mgem: 'mruby-json'
  add_dep.call 'mruby-open3',       github: 'dsisnero/mruby-open3'
  add_dep.call 'mruby-optparse',    mgem: 'mruby-optparse'
  add_dep.call 'mruby-shellwords',  github: 'dsisnero/mruby-shellwords'
  add_dep.call 'mruby-specinfra',   github: 'dsisnero/mruby-specinfra'

  add_dep.call 'mruby-tempfile',  github: 'dsisnero/mruby-tempfile'
  add_dep.call 'mruby-yaml',      github: 'mrbgems/mruby-yaml'
  add_dep.call 'mruby-erb',       github: 'dsisnero/mruby-erb'
  add_dep.call 'mruby-etc',       github: 'dsisnero/mruby-etc'
  add_dep.call 'mruby-process',   github: 'dsisnero/mruby-process'
  add_dep.call 'mruby-uri',       github: 'zzak/mruby-uri'
  add_dep.call 'mruby-schash',    github: 'tatsushid/mruby-schash'
end
