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

    def to_comments(exp)
      inner = exp.map do |sub_exp|
        if sub_exp.is_a? Sexp
          to_comments sub_exp
        else
          sub_exp
        end
      end

      comments = exp.comments.to_s.gsub(/\n\s*\n/, "\n")
      if comments.empty?
        s(*inner)
      else
        s(:comment, comments, s(*inner))
      end
    end

    def assert_parsed_as(sexp, code, extra_compatible: false)
      parser = RipperParser::Parser.new
      parser.extra_compatible = extra_compatible
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
      newparser.extra_compatible = true
      expected = oldparser.parse code.dup
      result = newparser.parse code
      # expected = to_comments expected
      # result = to_comments result
      # require 'pry'
      # binding.pry
      assert_equal formatted(expected), formatted(result)
    end
  end

  module Expectations
    infect_an_assertion :assert_parsed_as, :must_be_parsed_as
    infect_an_assertion :assert_parsed_as_before, :must_be_parsed_as_before, :unary
  end
end
