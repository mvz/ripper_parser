# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/clean"
require "rake/testtask"
require 'rake/manifest/task'

namespace :test do
  Rake::TestTask.new(:unit) do |t|
    t.libs = ["lib"]
    t.test_files = FileList["test/ripper_parser/**/*_test.rb"]
    t.warning = true
  end

  Rake::TestTask.new(:end_to_end) do |t|
    t.libs = ["lib"]
    t.test_files = FileList["test/end_to_end/*_test.rb"]
    t.warning = true
  end

  desc "Run all test suites"
  task run: [:unit, :end_to_end]
end

desc "Alias to test:run"
task test: "test:run"

Rake::Manifest::Task.new do |t|
  t.patterns = ['lib/**/*', 'CHANGELOG.md', 'README.md']
end

task build: 'manifest:check'

task default: :test
