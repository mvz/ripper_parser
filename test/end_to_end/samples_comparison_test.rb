# frozen_string_literal: true

require File.expand_path("../test_helper.rb", File.dirname(__FILE__))

describe "Using RipperParser and Parser" do
  make_my_diffs_pretty!

  Dir.glob(File.expand_path("../samples/*.rb", File.dirname(__FILE__))).each do |file|
    it "gives the same result for #{file}" do
      program = File.read file
      _(program).must_be_parsed_as_before
    end
  end
end
