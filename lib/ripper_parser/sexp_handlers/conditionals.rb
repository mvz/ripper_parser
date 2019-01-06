# frozen_string_literal: true

module RipperParser
  module SexpHandlers
    # Sexp handlers for conditionals
    module Conditionals
      def process_if(exp)
        _, cond, truepart, falsepart = exp.shift 4

        s(:if,
          handle_condition(cond),
          handle_consequent(truepart),
          handle_consequent(falsepart))
      end

      def process_elsif(exp)
        _, cond, truepart, falsepart = exp.shift 4

        s(:if,
          handle_condition(cond),
          handle_consequent(truepart),
          handle_consequent(falsepart))
      end

      def process_if_mod(exp)
        _, cond, truepart = exp.shift 3

        s(:if,
          handle_condition(cond),
          process(truepart),
          nil)
      end

      def process_unless(exp)
        _, cond, truepart, falsepart = exp.shift 4

        s(:if,
          handle_condition(cond),
          handle_consequent(falsepart),
          handle_consequent(truepart))
      end

      def process_unless_mod(exp)
        _, cond, truepart = exp.shift 3

        s(:if,
          handle_condition(cond),
          nil,
          process(truepart))
      end

      def process_case(exp)
        _, expr, clauses = exp.shift 3
        s(:case, process(expr), *process(clauses))
      end

      def process_when(exp)
        _, values, truepart, falsepart = exp.shift 4

        falsepart = process(falsepart)
        falsepart = unwrap_nil falsepart if falsepart

        if falsepart.nil?
          falsepart = [nil]
        elsif falsepart.first.is_a? Symbol
          falsepart = s(falsepart)
        end
        falsepart = [nil] if falsepart.empty?

        values = handle_argument_list values

        truepart = unwrap_nil process truepart

        s(s(:when,
            *values,
            truepart),
          *falsepart)
      end

      def process_else(exp)
        _, body = exp.shift 2
        process(body)
      end

      private

      def handle_condition(cond)
        cond = process(cond)
        case cond.sexp_type
        when :regexp
          return s(:match_current_line, cond)
        when :irange
          return s(:iflipflop, *cond[1..-1])
        when :erange
          return s(:eflipflop, *cond[1..-1])
        end
        cond
      end

      def handle_consequent(exp)
        unwrap_nil process(exp) if exp
      end
    end
  end
end
