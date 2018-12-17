module RipperParser
  module SexpHandlers
    # Sexp handlers for hash literals
    module Hashes
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

      # Handle implied hashes, such as at the end of argument lists.
      def process_bare_assoc_hash(exp)
        _, elems = exp.shift 2
        s(:hash, *map_process_list(elems))
      end
    end
  end
end
