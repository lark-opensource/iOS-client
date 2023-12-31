# frozen_string_literal: true

require_relative "version"

Gem::Specification.new do |spec|
  spec.name = "bitsky-lark"
  spec.version = Bitsky_Lark::VERSION
  spec.authors = ["supeng.charlie"]
  spec.email = ["supeng.charlie@bytedance.com"]

  spec.summary = "Write a short summary, because RubyGems requires one."
  spec.description = "Write a longer description or delete this line."
  spec.homepage = "https://example.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://example.com"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = 'https://code.byted.org/lark/iOS-client'
  spec.metadata["changelog_uri"] = 'https://code.byted.org/lark/iOS-client'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }  
  spec.require_paths = ["lib"]

  spec.add_dependency 'optparse'
  spec.add_dependency 'xcodeproj'
  spec.add_dependency 'cocoapods'  
  spec.add_dependency 'progressbar'
  spec.add_dependency 'cocoapods-bitsky'
  spec.add_dependency "rubycli"
end
