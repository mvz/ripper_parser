# frozen_string_literal: true

require "rake/clean"
require "bundler/gem_tasks"
require "rake/testtask"

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

task default: :test
