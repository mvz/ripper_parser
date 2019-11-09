# frozen_string_literal: true

require File.join(File.dirname(__FILE__), "lib/ripper_parser/version.rb")

Gem::Specification.new do |s|
  s.name = "ripper_parser"
  s.version = RipperParser::VERSION

  s.summary = "Parse with Ripper, produce sexps that are compatible with Parser."
  s.required_ruby_version = ">= 2.4.0"

  s.authors = ["Matijs van Zuijlen"]
  s.email = ["matijs@matijs.net"]
  s.homepage = "http://www.github.com/mvz/ripper_parser"

  s.license = "MIT"

  s.description = <<-DESC
    RipperParser is a parser for Ruby based on Ripper that aims to be a
    drop-in replacement for Parser.
  DESC

  s.rdoc_options = ["--main", "README.md"]

  s.files = Dir["{lib,test}/**/*", "*.md", "Rakefile"] & `git ls-files -z`.split("\0")
  s.extra_rdoc_files = ["README.md"]
  s.test_files = `git ls-files -z -- test`.split("\0")

  s.add_dependency("sexp_processor", ["~> 4.10"])

  s.add_development_dependency("minitest", ["~> 5.12"])
  s.add_development_dependency("parser", ["~> 2.6.0"])
  s.add_development_dependency("rake", ["~> 13.0"])
  s.add_development_dependency("simplecov")

  s.require_paths = ["lib"]
end
