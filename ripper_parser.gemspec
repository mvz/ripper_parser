# frozen_string_literal: true

require_relative "lib/ripper_parser/version"

Gem::Specification.new do |spec|
  spec.name = "ripper_parser"
  spec.version = RipperParser::VERSION
  spec.authors = ["Matijs van Zuijlen"]
  spec.email = ["matijs@matijs.net"]

  spec.summary = "Parse with Ripper, produce sexps that are compatible with Parser."
  spec.description = <<~DESC
    RipperParser is a parser for Ruby based on Ripper that aims
    to be a drop-in replacement for Parser.
  DESC
  spec.homepage = "http://www.github.com/mvz/ripper_parser"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mvz/ripper_parser"
  spec.metadata["changelog_uri"] = "https://github.com/mvz/ripper_parser/blob/master/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = File.readlines("Manifest.txt", chomp: true)
  spec.require_paths = ["lib"]

  spec.rdoc_options = ["--main", "README.md"]
  spec.extra_rdoc_files = ["README.md", "CHANGELOG.md"]

  spec.add_runtime_dependency "sexp_processor", "~> 4.10"

  spec.add_development_dependency "minitest", "~> 5.15"
  spec.add_development_dependency "minitest-focus", "~> 1.3"
  spec.add_development_dependency "parser", "~> 3.2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rake-manifest", "~> 0.2.0"
  spec.add_development_dependency "rubocop", "~> 1.32"
  spec.add_development_dependency "rubocop-minitest", "~> 0.30.0"
  spec.add_development_dependency "rubocop-performance", "~> 1.13"
  spec.add_development_dependency "simplecov", "~> 0.22.0"
end
