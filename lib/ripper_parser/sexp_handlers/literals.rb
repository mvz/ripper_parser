module RipperParser
  module SexpHandlers
    # Sexp handlers for literals, except hash and array literals
    module Literals
      def process_string_literal(exp)
        _, content = exp.shift 2
        process(content)
      end

      def process_string_content(exp)
        _, *rest = shift_all exp
        parts = extract_string_parts(rest)

        if parts.empty?
          s(:str, '')
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

      def process_at_tstring_content(exp)
        _, content, _, delim = exp.shift 4
        string = case delim
                 when /^<<[-~]?'/
                   content
                 when /^<</
                   unescape(content)
                 when '"', '`', ':"', /^%Q.$/, /^%.$/
                   fix_encoding unescape(content)
                 when /^%[WI].$/
                   fix_encoding unescape_wordlist_word(content)
                 when "'", ":'", /^%q.$/
                   fix_encoding simple_unescape(content)
                 when '/', /^%r.$/
                   fix_encoding unescape_regexp(content)
                 when /^%[wi].$/
                   fix_encoding simple_unescape_wordlist_word(content)
                 else
                   fix_encoding content
                 end
        s(:str, string)
      end

      private

      def extract_string_parts(list)
        parts = map_process_list list
        result = []
        parts.each do |sub_expr|
          case sub_expr.sexp_type
          when :dstr
            result.push(*sub_expr.sexp_body)
          when :str
            result.push(sub_expr) unless sub_expr[1] == ''
          else
            result.push(sub_expr)
          end
        end
        result
      end

      def character_flags_to_regopt(flags)
        s(:regopt, *flags.chars.grep(/[a-z]/).sort.map(&:to_sym))
      end

      def handle_dyna_symbol_content(node)
        type, *body = *process(node)
        case type
        when :str
          s(:sym, body.first.to_sym)
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
        if node.sexp_type == :'@tstring_content'
          processed = process(node)
          symbol = processed[1].to_sym
          with_line_number(processed.line, s(:sym, symbol))
        else
          symbol, position = extract_node_symbol_with_position(node)
          with_position(position, s(:sym, symbol))
        end
      end
    end
  end
end
