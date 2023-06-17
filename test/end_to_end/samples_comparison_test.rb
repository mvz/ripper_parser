# frozen_string_literal: true

require File.expand_path("../test_helper.rb", File.dirname(__FILE__))

describe "Using RipperParser and Parser" do
  make_my_diffs_pretty!

  Dir.glob(File.expand_path("../samples/*.rb", File.dirname(__FILE__))).each do |file|
    next if RUBY_VERSION < "3.0.0" && file.match?(/_30.rb\Z/)
    next if RUBY_VERSION < "3.1.0" && file.match?(/_31.rb\Z/)

    it "gives the same result for #{file}" do
      program = File.read file
      _(program).must_be_parsed_as_before
    end
  end
end
