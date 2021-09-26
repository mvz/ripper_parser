# frozen_string_literal: true

module RipperParser
  module SexpHandlers
    # Sexp handlers for literals
    module Literals
      # character literals
      def process_at_CHAR(exp)
        _, val, pos = exp.shift 3
        with_position(pos, s(:str, unescape(val[1..])))
      end

      def process_array(exp)
        _, elems = exp.shift 2
        return s(:array) if elems.nil?

        s(:array, *process(elems).sexp_body)
      end

      # Handle hash literals sexps. These can be either empty, or contain a
      # nested :assoclist_from_args Sexp.
      #
      # @example Empty hash
      #   s(:hash, nil)
      # @example Hash with contents
      #   s(:hash, s(:assoclist_from_args, ...))
      def process_hash(exp)
        _, body = exp.shift 2
        return s(:hash) unless body

        _, elems = body
        s(:hash, *map_process_list(elems))
      end

      # @example
      #   s(:assoc_splat, s(:vcall, s(:@ident, "bar")))
      def process_assoc_splat(exp)
        _, param = exp.shift 2
        s(:kwsplat, process(param))
      end

      # @example
      #   s(:assoc_new, s(:@label, "baz:", s(1, 9)), s(:vcall, s(:@ident, "qux", s(1, 14))))
      def process_assoc_new(exp)
        _, left, right = exp.shift 3
        s(:pair, process(left), process(right))
      end

      # number literals
      def process_at_int(exp)
        _, val, pos = exp.shift 3
        with_position(pos, s(:int, Integer(val)))
      end

      def process_at_float(exp)
        _, val, pos = exp.shift 3
        with_position(pos, s(:float, val.to_f))
      end

      def process_at_rational(exp)
        _, val, pos = exp.shift 3
        with_position(pos, s(:rational, val.to_r))
      end

      def process_at_imaginary(exp)
        _, val, pos = exp.shift 3
        with_position(pos, s(:complex, val.to_c))
      end
    end
  end
end
