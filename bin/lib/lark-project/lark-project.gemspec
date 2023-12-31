# frozen_string_literal: true

require_relative 'lib/lark/project/version'

Gem::Specification.new do |spec|
  spec.name          = 'lark-project'
  spec.version       = Lark::Project::VERSION
  spec.authors       = ['王孝华']
  spec.email         = ['wangxiaohua@bytedance.com']

  spec.summary       = 'lark project相关可复用的配置和扩展'
  spec.description   = 'lark project相关可复用的配置和扩展'
  spec.homepage      = 'https://code.byted.org/lark/iOS-client'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.byted.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'cocoapods'
  # 公司库
  spec.add_dependency 'cocoapods-remote-resolve', '>= 0.1.11'
  spec.add_dependency 'seer-optimize'
  spec.add_dependency 'cocoapods-dancecc-toolchain', '>= 0.2.1'
  # 自研库
  spec.add_dependency 'cocoapods-downloader-sharedcache', '>= 0.1.1'
  spec.add_dependency 'EEScaffold', '>= 0.1.404'
  spec.add_dependency 'lark_mod_manager', '>= 0.1.34'
  spec.add_dependency 'rubycli', '>= 0.2.4'

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
