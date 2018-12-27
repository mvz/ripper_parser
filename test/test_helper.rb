# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
end

require 'minitest/autorun'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'ripper_parser'
require 'parser/current'
Parser::Builders::Default.emit_lambda   = true
Parser::Builders::Default.emit_procarg0 = true
Parser::Builders::Default.emit_encoding = true
Parser::Builders::Default.emit_index    = true

module MiniTest
  class Spec
    def formatted(exp)
      exp.inspect.gsub(/^  */, '').gsub(/, s\(/, ",\ns(").gsub(/\), /, "),\n")
    end

    def assert_parsed_as(sexp, code)
      parser = RipperParser::Parser.new
      result = parser.parse code
      if sexp.nil?
        assert_nil result
      else
        assert_equal sexp, result
        assert_equal sexp.to_s, result.to_s
      end
    end

    def assert_parsed_as_before(code)
      oldparser = Parser::CurrentRuby
      newparser = RipperParser::Parser.new
      expected = oldparser.parse code.dup
      result = newparser.parse code
      assert_equal formatted(expected), formatted(result)
    end
  end

  module Expectations
    infect_an_assertion :assert_parsed_as, :must_be_parsed_as
    infect_an_assertion :assert_parsed_as_before, :must_be_parsed_as_before, :unary
  end
end
