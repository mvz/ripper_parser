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
        string, rest = extract_string_parts(rest)

        if rest.empty?
          s(:str, string)
        else
          s(:dstr, string, *rest)
        end
      end

      alias process_word process_string_content

      def process_string_embexpr(exp)
        _, list = exp.shift 2

        val = process(list.sexp_body.first)

        case val.sexp_type
        when :str
          val
        when :void_stmt
          s(:dstr, '', s(:begin))
        else
          s(:dstr, '', s(:begin, val))
        end
      end

      def process_string_dvar(exp)
        _, list = exp.shift 2
        val = process(list)
        s(:dstr, '', s(:begin, val))
      end

      def process_string_concat(exp)
        _, left, right = exp.shift 3

        left = process(left)
        right = process(right)

        if left.sexp_type == :str
          merge_left_into_right(left, right)
        else
          merge_right_into_left(left, right)
        end
      end

      def process_xstring_literal(exp)
        _, content = exp.shift 2
        process(content)
      end

      def process_xstring(exp)
        _, *rest = shift_all exp
        string, rest = extract_string_parts(rest)
        if rest.empty?
          s(:xstr, string)
        else
          s(:dxstr, string, *rest)
        end
      end

      def process_regexp_literal(exp)
        _, content, (_, flags,) = exp.shift 3

        string, rest = process(content).sexp_body
        optflags = character_flags_to_regopt flags

        if rest.empty?
          s(:regexp, s(:str, string), optflags)
        else
          if string.empty?
            s(:regexp, *rest, optflags)
          else
            s(:regexp, s(:str, string), *rest, optflags)
          end
        end
      end

      def process_regexp(exp)
        _, *rest = shift_all exp
        string, rest = extract_string_parts(rest)
        s(:regexp, string, rest)
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
        parts = []

        unless list.empty?
          parts << process(list.shift)
          list.each do |item|
            parts << if extra_compatible && item.sexp_type == :@tstring_content
                       alternative_process_at_tstring_content(item)
                     else
                       process(item)
                     end
          end
        end

        string = ''
        while !parts.empty? && parts.first.sexp_type == :str
          str = parts.shift
          string += str[1]
        end

        rest = parts.map { |se| se.sexp_type == :dstr ? se.last : se }

        return string, rest
      end

      def alternative_process_at_tstring_content(exp)
        _, content, _, delim = exp.shift 4
        string = case delim
                 when /^<<[-~]?'/
                   content
                 when /^<</
                   unescape(content)
                 when '"', '`', ':"', /^%Q.$/, /^%.$/
                   unescape(content)
                 when /^%[WI].$/
                   unescape_wordlist_word(content)
                 when "'", ":'", /^%q.$/
                   simple_unescape(content)
                 when '/', /^%r.$/
                   unescape_regexp(content)
                 when /^%[wi].$/
                   simple_unescape_wordlist_word(content)
                 else
                   content
                 end
        string.force_encoding('ascii-8bit') if string == "\0"
        s(:str, string)
      end

      def character_flags_to_regopt(flags)
        s(:regopt, *flags.chars.grep(/[a-z]/).sort.map(&:to_sym))
      end

      def character_flags_to_numerical(flags)
        numflags = 0

        flags =~ /m/ and numflags |= Regexp::MULTILINE
        flags =~ /x/ and numflags |= Regexp::EXTENDED
        flags =~ /i/ and numflags |= Regexp::IGNORECASE

        flags =~ /n/ and numflags |= Regexp::NOENCODING
        flags =~ /[ues]/ and numflags |= Regexp::FIXEDENCODING

        numflags
      end

      def handle_dyna_symbol_content(node)
        type, *body = *process(node)
        case type
        when :str, :xstr
          s(:sym, body.first.to_sym)
        when :dstr, :dxstr
          s(:dsym, *body)
        else
          raise type.to_s
        end
      end

      def handle_symbol_content(node)
        if node.sexp_type == :'@kw'
          symbol, position = extract_node_symbol_with_position(node)
          with_line_number(position, s(:sym, symbol))
        else
          processed = process(node)
          symbol = processed[1].to_sym
          with_line_number(processed.line, s(:sym, symbol))
        end
      end

      def merge_left_into_right(left, right)
        right[1] = left[1] + right[1]
        right
      end

      def merge_right_into_left(left, right)
        if right.sexp_type == :str
          left.push right
        else
          _, first, *rest = right
          left.push s(:str, first) unless first.empty?
          left.push(*rest)
        end
      end
    end
  end
end
