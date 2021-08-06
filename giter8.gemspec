# frozen_string_literal: true

require_relative "lib/giter8/version"

Gem::Specification.new do |spec|
  spec.name          = "giter8"
  spec.version       = Giter8::VERSION
  spec.authors       = ["Victor Gama"]
  spec.email         = ["hey@vito.io"]

  spec.summary       = "giter8 implements giter8 rendering mechanisms"
  spec.description   = "giter8 implements giter8 rendering mechanisms"
  spec.homepage      = "https://github.com/heyvito/giter8.rb"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "ptools", "~> 1.4", ">= 1.4.2"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
