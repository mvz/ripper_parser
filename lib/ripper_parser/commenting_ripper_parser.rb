# frozen_string_literal: true

require "ripper"
require "ripper_parser/syntax_error"
require "ripper_parser/unescape"

module RipperParser
  # Variant of Ripper's SexpBuilder parser class that inserts comments as
  # Sexps into the built parse tree.
  #
  # @api private
  class CommentingRipperParser < Ripper::SexpBuilder
    def initialize(*args)
      super
      @comment = ""

      @comment_stack = []
      @delimiter_stack = []
      @operator_stack = []

      @in_symbol = false
    end

    def parse
      result = super
      raise "Ripper parse failed." unless result

      Sexp.from_array(result)
    end

    private

    def on_backtick(delimiter)
      @delimiter_stack.push delimiter
      super
    end

    def on_begin(*args)
      commentize(:begin, super)
    end

    def on_void_stmt
      result = super
      result << [lineno, column]
    end

    def on_comment(tok)
      @comment += tok
    end

    def on_embdoc_beg(tok)
      @comment += tok
    end

    def on_embdoc(tok)
      @comment += tok
    end

    def on_embdoc_end(tok)
      @comment += tok
    end

    def on_kw(tok)
      result = super
      case tok
      when "class", "def", "module", "BEGIN", "begin", "END"
        unless @in_symbol
          @comment_stack.push [result, @comment]
          @comment = ""
        end
      when "in"
        @operator_stack.push tok
      end
      result
    end

    def on_module(*args)
      commentize(:module, super)
    end

    def on_class(*args)
      commentize(:class, super)
    end

    def on_sclass(*args)
      commentize(:class, super)
    end

    def on_def(*args)
      commentize(:def, super)
    end

    def on_defs(*args)
      commentize(:def, super)
    end

    def on_args_new
      [:args]
    end

    def on_args_add(list, elem)
      list << elem
    end

    def on_heredoc_beg(delimiter)
      @delimiter_stack.push delimiter
    end

    def on_heredoc_dedent(val, width)
      next_dedent = true
      val.map! do |e|
        if e.is_a?(Array) && e[0] == :@tstring_content
          e = dedent_element(e, width) if next_dedent
          next_dedent = e[1].end_with? "\n"
        end
        e
      end
      val
    end

    def on_heredoc_end(_delimiter)
      @delimiter_stack.pop
    end

    def on_mlhs_new
      [:mlhs]
    end

    def on_mlhs_add(list, elem)
      if list.first == :mlhs
        list << elem
      else
        [:mlhs_add_post, list, elem]
      end
    end

    def on_mrhs_new
      [:mrhs]
    end

    def on_mrhs_add(list, elem)
      list << elem
    end

    def on_qsymbols_beg(delimiter)
      @delimiter_stack.push delimiter
    end

    def on_qsymbols_new
      [:qsymbols]
    end

    def on_qsymbols_add(list, elem)
      list << elem
    end

    def on_qwords_beg(delimiter)
      @delimiter_stack.push delimiter
    end

    def on_qwords_new
      [:qwords]
    end

    def on_qwords_add(list, elem)
      list << elem
    end

    def on_regexp_beg(delimiter)
      @delimiter_stack.push delimiter
    end

    def on_regexp_end(delimiter)
      @delimiter_stack.pop
      super
    end

    def on_regexp_new
      [:regexp]
    end

    def on_regexp_add(list, elem)
      list << elem
    end

    def on_stmts_new
      [:stmts]
    end

    def on_stmts_add(list, elem)
      list << elem
    end

    def on_string_add(list, elem)
      list << elem
    end

    def on_symbols_beg(delimiter)
      @delimiter_stack.push delimiter
    end

    def on_symbols_new
      [:symbols]
    end

    def on_symbols_add(list, elem)
      list << elem
    end

    def on_tstring_beg(delimiter)
      @delimiter_stack.push delimiter
    end

    def on_tstring_content(content)
      super << @delimiter_stack.last
    end

    def on_tstring_end(delimiter)
      @delimiter_stack.pop
      super
    end

    def on_word_new
      [:word]
    end

    def on_word_add(list, elem)
      list << elem
    end

    def on_words_beg(delimiter)
      @delimiter_stack.push delimiter
    end

    def on_words_new
      [:words]
    end

    def on_words_add(list, elem)
      list << elem
    end

    def on_xstring_new
      [:xstring]
    end

    def on_xstring_add(list, elem)
      list << elem
    end

    def on_in(*args)
      in_type = @operator_stack.pop
      case in_type
      when "in"
        super
      when "=>"
        args.unshift :right_assign
      else
        raise "Expected either 'in' or '=>' operator"
      end
    end

    def on_op(token)
      @operator_stack.push token if token == "=>"
      super
    end

    def on_binary(left, operator, right)
      if operator == :"=>"
        raise "Expected operator stack to contain '=>'" unless @operator_stack.last == "=>"

        @operator_stack.pop
      end
      super
    end

    NUMBER_LITERAL_TYPES = [:@imaginary, :@int, :@float, :@rational].freeze
    private_constant :NUMBER_LITERAL_TYPES

    def on_unary(operator, value)
      if operator == :-@ && NUMBER_LITERAL_TYPES.include?(value.first)
        type, literal, lines = value
        if literal[0] == "-"
          super
        else
          [type, "-#{literal}", lines]
        end
      elsif operator == :+@ && NUMBER_LITERAL_TYPES.include?(value.first)
        type, literal, lines = value
        if literal[0] == "+"
          super
        else
          [type, literal, lines]
        end
      else
        super
      end
    end

    def on_symbeg(delimiter)
      @delimiter_stack.push delimiter
      @in_symbol = true
    end

    def on_symbol(*args)
      @delimiter_stack.pop
      @in_symbol = false
      super
    end

    def on_embexpr_beg(_delimiter)
      @in_symbol = false
    end

    def on_dyna_symbol(*args)
      @in_symbol = false
      super
    end

    def on_BEGIN(*args)
      commentize(:BEGIN, super)
    end

    def on_END(*args)
      commentize(:END, super)
    end

    def on_parse_error(message)
      super
      raise SyntaxError, message if message.start_with?("syntax error,")
    end

    def on_class_name_error(message, *)
      raise SyntaxError, message
    end

    def on_alias_error(message, *)
      raise SyntaxError, message
    end

    def on_assign_error(message, *)
      raise SyntaxError, message
    end

    def on_param_error(message, *)
      raise SyntaxError, message
    end

    def commentize(_name, exp)
      (_, _kw, loc), comment = @comment_stack.pop
      @comment = ""
      exp.push loc
      [:comment, comment, exp]
    end
  end
end
