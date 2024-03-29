# frozen_string_literal: true

module RipperParser
  module SexpHandlers
    # Sexp handlers for string and string-like literals
    module StringLiterals
      def process_string_literal(exp)
        _, content = exp.shift 2
        process(content)
      end

      def process_string_content(exp)
        _, *rest = shift_all exp
        parts = extract_string_parts(rest)

        if parts.empty?
          s(:str, "")
        elsif parts.length == 1 && parts.first.sexp_type == :str
          parts.first
        else
          s(:dstr, *parts)
        end
      end

      alias process_word process_string_content

      def process_string_embexpr(exp)
        _, list = exp.shift 2

        val = process(list.sexp_body.first)

        case val.sexp_type
        when :void_stmt
          s(:dstr, s(:begin))
        else
          s(:dstr, s(:begin, val))
        end
      end

      def process_string_dvar(exp)
        _, list = exp.shift 2
        val = process(list)
        s(:dstr, s(:begin, val))
      end

      def process_string_concat(exp)
        _, left, right = exp.shift 3

        left = process(left)
        right = process(right)

        s(:dstr, left, right)
      end

      def process_xstring_literal(exp)
        _, content = exp.shift 2
        process(content)
      end

      def process_xstring(exp)
        _, *rest = shift_all exp
        rest = extract_string_parts(rest)
        s(:xstr, *rest)
      end

      def process_regexp_literal(exp)
        _, content, (_, flags,) = exp.shift 3

        regexp = process(content)
        optflags = character_flags_to_regopt flags
        regexp << optflags
      end

      def process_regexp(exp)
        _, *rest = shift_all exp
        rest = extract_string_parts(rest)
        s(:regexp, *rest)
      end

      def process_symbol_literal(exp)
        _, symbol = exp.shift 2
        if symbol.sexp_type == :symbol
          process(symbol)
        else
          handle_symbol_content(symbol)
        end
      end

      def process_symbol(exp)
        _, node = exp.shift 2
        handle_symbol_content(node)
      end

      def process_dyna_symbol(exp)
        _, node = exp.shift 2
        handle_dyna_symbol_content(node)
      end

      def process_qsymbols(exp)
        _, *items = shift_all(exp)
        items = items.map { |item| handle_symbol_content(item) }
        s(:qsymbols, *items)
      end

      def process_symbols(exp)
        _, *items = shift_all(exp)
        items = items.map { |item| handle_dyna_symbol_content(item) }
        s(:symbols, *items)
      end

      INTERPOLATING_HEREDOC = /^<<[-~]?[^-'~]/
      NON_INTERPOLATING_HEREDOC = /^<<[-~]?'/
      INTERPOLATING_STRINGS = ['"', "`", ':"', /^%Q.$/, /^%.$/].freeze
      NON_INTERPOLATING_STRINGS = ["'", ":'", /^%q.$/].freeze
      INTERPOLATING_WORD_LIST = /^%[WI].$/
      NON_INTERPOLATING_WORD_LIST = /^%[wi].$/
      REGEXP_LITERALS = ["/", /^%r.$/].freeze

      def process_at_tstring_content(exp)
        _, content, pos, delim = exp.shift 4
        content = perform_line_continuation_unescapes content, delim

        parts = case delim
                when INTERPOLATING_WORD_LIST, NON_INTERPOLATING_WORD_LIST
                  [content]
                else
                  if content.include?("\n")
                    content.split(/(\n)/).each_slice(2).map(&:join)
                  else
                    [content]
                  end
                end

        parts = parts.map { |it| perform_unescapes(it, delim) }
        parts = parts.map { |it| s(:str, it) }

        result = if parts.length == 1
                   parts.first
                 else
                   s(:dstr, *parts)
                 end
        with_position(pos, result)
      end

      private

      def extract_string_parts(list)
        list = merge_raw_string_literals list
        parts = map_process_list list
        result = []
        parts.each do |sub_expr|
          case sub_expr.sexp_type
          when :dstr
            result.push(*sub_expr.sexp_body)
          when :str
            result.push(sub_expr)
          end
        end
        result
      end

      def merge_raw_string_literals(list)
        chunks = list.chunk { |it| it.sexp_type == :@tstring_content }
        chunks.flat_map do |is_simple, items|
          if is_simple
            head = items.first
            contents = items.map { |it| it[1] }.join
            if contents.empty?
              []
            else
              [s(:@tstring_content, contents, head[2], head[3])]
            end
          else
            items
          end
        end
      end

      def character_flags_to_regopt(flags)
        s(:regopt, *flags.chars.grep(/[a-z]/).sort.map(&:to_sym))
      end

      def handle_dyna_symbol_content(node)
        type, *body = *process(node)
        case type
        when :str
          if body.first.empty?
            s(:dsym)
          else
            s(:sym, body.first.to_sym)
          end
        when :xstr
          if body.length == 1 && body.first.sexp_type == :str
            s(:sym, body.first[1].to_sym)
          else
            s(:dsym, *body)
          end
        when :dstr
          s(:dsym, *body)
        end
      end

      def handle_symbol_content(node)
        if node.sexp_type == :@tstring_content
          processed = process(node)
          symbol = processed[1].to_sym
          with_line_number(processed.line, s(:sym, symbol))
        else
          symbol, position = extract_node_symbol_with_position(node)
          with_position(position, s(:sym, symbol))
        end
      end

      def perform_line_continuation_unescapes(content, delim)
        case delim
        when INTERPOLATING_HEREDOC, *INTERPOLATING_STRINGS, *REGEXP_LITERALS
          unescape_continuations content
        else
          content
        end
      end

      def perform_unescapes(content, delim)
        content.gsub!("\r\n", "\n")
        result = case delim
                 when NON_INTERPOLATING_HEREDOC
                   content
                 when INTERPOLATING_HEREDOC, *INTERPOLATING_STRINGS, INTERPOLATING_WORD_LIST
                   unescape(content)
                 when *NON_INTERPOLATING_STRINGS
                   simple_unescape(content, delim)
                 when *REGEXP_LITERALS
                   unescape_regexp(content)
                 when NON_INTERPOLATING_WORD_LIST
                   simple_unescape_wordlist_word(content, delim)
                 end
        raise SyntaxError unless result.valid_encoding?

        result
      end
    end
  end
end
