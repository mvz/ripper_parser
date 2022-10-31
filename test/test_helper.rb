# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/test/"
  enable_coverage :branch
end

require "minitest/autorun"
require "minitest/focus"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "ripper_parser"
require "parser/current"
Parser::Builders::Default.emit_lambda              = true
Parser::Builders::Default.emit_procarg0            = true
Parser::Builders::Default.emit_encoding            = true
Parser::Builders::Default.emit_index               = true
Parser::Builders::Default.emit_arg_inside_procarg0 = true
Parser::Builders::Default.emit_forward_arg         = true
Parser::Builders::Default.emit_kwargs              = true
Parser::Builders::Default.emit_match_pattern       = true

module MiniTest
  class Spec
    def inspect_with_line_numbers(exp)
      parts = exp.map do |sub_exp|
        if sub_exp.is_a? Sexp
          inspect_with_line_numbers(sub_exp)
        else
          sub_exp.inspect
        end
      end

      plain = "s(#{parts.join(', ')})"
      # HACK: Empty args sexp sometimes has no line number in Parser
      return plain if plain == "s(:args)"

      if (line = exp.line)
        "#{plain}.line(#{line})"
      else
        plain
      end
    end

    def inspect_with_line_numbers_ast(exp)
      parts = exp.children.map do |sub_exp|
        if sub_exp.is_a? AST::Node
          inspect_with_line_numbers_ast(sub_exp)
        else
          sub_exp.inspect
        end
      end

      parts.unshift exp.type.inspect

      plain = "s(#{parts.join(', ')})"
      # HACK: Empty args sexp sometimes has no line number in Parser
      return plain if plain == "s(:args)"

      if (line = exp.location.line)
        "#{plain}.line(#{line})"
      else
        plain
      end
    end

    def formatted(exp, with_line_numbers: false)
      inspection = if with_line_numbers
                     inspect_with_line_numbers(exp)
                   else
                     exp.inspect
                   end
      inspection.gsub(/^  */, "").gsub(/, s\(/, ",\ns(").gsub(/\), /, "),\n")
    end

    def formatted_ast(exp, with_line_numbers: false)
      inspection = if with_line_numbers
                     inspect_with_line_numbers_ast(exp)
                   else
                     exp.inspect
                   end
      inspection.gsub(/^  */, "").gsub(/, s\(/, ",\ns(").gsub(/\), /, "),\n")
    end

    def assert_parsed_as(sexp, code, with_line_numbers: false)
      parser = RipperParser::Parser.new
      result = parser.parse code
      if sexp.nil?
        assert_nil result
      else
        assert_equal sexp, result
        assert_equal(formatted(sexp, with_line_numbers: with_line_numbers),
                     formatted(result, with_line_numbers: with_line_numbers))
      end
    end

    def assert_parsed_as_before(code, with_line_numbers: false)
      oldparser = Parser::CurrentRuby
      newparser = RipperParser::Parser.new
      expected = oldparser.parse code.dup
      result = newparser.parse code

      assert_equal(formatted_ast(expected, with_line_numbers: with_line_numbers),
                   formatted(result, with_line_numbers: with_line_numbers))
    end
  end

  Expectation.class_eval do
    def must_be_parsed_as(sexp, with_line_numbers: false)
      ctx.assert_parsed_as(sexp, target, with_line_numbers: with_line_numbers)
    end

    def must_be_parsed_as_before(with_line_numbers: false)
      ctx.assert_parsed_as_before(target, with_line_numbers: with_line_numbers)
    end
  end
end
