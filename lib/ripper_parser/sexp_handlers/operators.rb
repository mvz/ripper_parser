# frozen_string_literal: true

module RipperParser
  module SexpHandlers
    # Sexp handlers for operators
    module Operators
      BINARY_OPERATOR_MAP = {
        "&&": :and,
        "||": :or,
        and: :and,
        or: :or
      }.freeze

      UNARY_OPERATOR_MAP = {
        not: :!
      }.freeze

      def process_binary(exp)
        _, left, op, right = exp.shift 4

        if op == :=~
          make_regexp_match_operator(left, right)
        elsif (mapped = BINARY_OPERATOR_MAP[op])
          make_boolean_operator(mapped, left, right)
        elsif op == :"=>"
          s(:match_as, handle_pattern(left), handle_pattern(right))
        else
          s(:send, process(left), op, process(right))
        end
      end

      def process_unary(exp)
        _, op, arg = exp.shift 3
        arg = process(arg)
        op = UNARY_OPERATOR_MAP[op] || op
        s(:send, arg, op)
      end

      def process_dot2(exp)
        _, left, right = exp.shift 3
        left = process(left)
        right = process(right)
        s(:irange, left, right)
      end

      def process_dot3(exp)
        _, left, right = exp.shift 3
        left = process(left)
        right = process(right)
        s(:erange, left, right)
      end

      def process_ifop(exp)
        _, cond, truepart, falsepart = exp.shift 4
        s(:if,
          process(cond),
          process(truepart),
          process(falsepart))
      end

      private

      def make_boolean_operator(operator, left, right)
        s(operator, process(left), process(right))
      end

      def make_regexp_match_operator(left, right)
        left = process(left)
        right = process(right)
        if left.sexp_type == :regexp && (regexp = static_regexp(left))
          @local_variables += regexp.names.map(&:to_sym)
          s(:match_with_lvasgn, left, right)
        else
          s(:send, left, :=~, right)
        end
      end

      def static_regexp(exp)
        body = static_string(exp.sexp_body[0..-2]) or return

        Regexp.new(body)
      end

      def static_string(nodes)
        parts = nodes.map do |node|
          case node.sexp_type
          when :str
            node[1]
          when :begin
            static_string(node.sexp_body)
          end
        end
        parts.all? && parts.join
      end
    end
  end
end
