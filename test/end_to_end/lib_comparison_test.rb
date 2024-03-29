# frozen_string_literal: true

require File.expand_path("../test_helper.rb", File.dirname(__FILE__))

describe "Using RipperParser and Parser" do
  Dir.glob("lib/**/*.rb").each do |file|
    describe "for #{file}" do
      let :program do
        File.read file
      end

      it "gives the same result" do
        _(program).must_be_parsed_as_before
      end
    end
  end
end
