module RipperParser
  module SexpHandlers
    # Sexp handlers for operators
    module Operators
      BINARY_OPERATOR_MAP = {
        '&&': :and,
        '||': :or,
        and: :and,
        or: :or
      }.freeze

      UNARY_OPERATOR_MAP = {
        not: :!
      }.freeze

      NEGATED_BINARY_OPERATOR_MAP = {
        '!~': :=~
      }.freeze

      SHIFT_OPERATORS = [:<<, :>>].freeze

      def process_binary(exp)
        _, left, op, right = exp.shift 4

        if op == :=~
          make_regexp_match_operator(op, left, right)
        elsif (mapped = NEGATED_BINARY_OPERATOR_MAP[op])
          s(:not, make_regexp_match_operator(mapped, left, right))
        elsif (mapped = BINARY_OPERATOR_MAP[op])
          make_boolean_operator(mapped, left, right)
        elsif SHIFT_OPERATORS.include? op
          s(:send, unwrap_begin(process(left)), op, unwrap_begin(process(right)))
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
        _, left, _, right = rebalance_binary(s(:binary, left, operator, right))
        s(operator, unwrap_begin(process(left)), process(right))
      end

      def make_regexp_match_operator(operator, left, right)
        s(:send, process(left), operator, process(right))
      end

      def rebalance_binary(exp)
        _, left, op, right = exp
        if left.sexp_type == :binary && BINARY_OPERATOR_MAP[op] == BINARY_OPERATOR_MAP[left[2]]
          _, left, _, middle = rebalance_binary(left)
          right = rebalance_binary(s(:binary, middle, op, right))
        end
        s(:binary, left, op, right)
      end
    end
  end
end
