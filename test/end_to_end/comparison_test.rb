# frozen_string_literal: true

require File.expand_path("../test_helper.rb", File.dirname(__FILE__))

describe "Using RipperParser and Parser" do
  describe "for a simple well known program" do
    let :program do
      "puts 'Hello World'"
    end

    it "gives the same result with line numbers" do
      _(program).must_be_parsed_as_before with_line_numbers: true
    end
  end

  describe "for a more complex program" do
    let :program do
      <<-RUBY
      module Quux
        class Foo
          def bar
            baz = 3
            qux baz
          end
          def qux it
            if it == 3
              [1,2,3].map {|i| 2*i}
            end
          end
        end
      end

      Quux::Foo.new.bar
      RUBY
    end

    it "gives the same result with line numbers" do
      _(program).must_be_parsed_as_before with_line_numbers: true
    end
  end

  describe "for an example with yield from Reek" do
    let :program do
      "def fred() yield(3) if block_given?; end"
    end

    it "gives the same result with line numbers" do
      _(program).must_be_parsed_as_before with_line_numbers: true
    end
  end

  describe "for an example with floats from Reek" do
    let :program do
      <<-RUBY
        def total_envy
          fred = @item
          total = 0
          total += fred.price
          total += fred.tax
          total *= 1.15
        end
      RUBY
    end

    it "gives the same result with line numbers" do
      _(program).must_be_parsed_as_before with_line_numbers: true
    end
  end

  describe "for an example with operators and explicit block parameter from Reek" do
    let :program do
      <<-RUBY
        def parse(arg, argv, &error)
          if !(val = arg) and (argv.empty? or /\\A-/ =~ (val = argv[0]))
            return nil, block, nil
          end
          opt = (val = parse_arg(val, &error))[1]
          val = conv_arg(*val)
          if opt and !arg
            argv.shift
          else
            val[0] = nil
          end
          val
        end
      RUBY
    end

    it "gives the same result with line numbers" do
      _(program).must_be_parsed_as_before with_line_numbers: true
    end
  end

  describe "for an example of a complex regular expression from Reek" do
    let :program do
      "/(\#{@types})\\s*(\\w+)\\s*\\(([^)]*)\\)/"
    end

    it "gives the same result with line numbers" do
      _(program).must_be_parsed_as_before with_line_numbers: true
    end
  end
end
