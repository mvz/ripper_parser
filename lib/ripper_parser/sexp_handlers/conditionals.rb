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

      # NOTE: Ripper generates a :case node even for one-line pattern matching,
      # which doesn't use the case keyword at all.
      def process_case(exp)
        _, expr, clauses = exp.shift 3
        expr = process(expr)

        case clauses.sexp_type
        when :in
          first, *rest = process(clauses)
          _, pattern, _, truepart = first
          if truepart.nil?
            s(:match_pattern_p, expr, pattern)
          else
            s(:case_match, expr, first, *rest)
          end
        when :right_assign
          _, pattern = process(clauses)
          s(:match_pattern, expr, pattern)
        else
          s(:case, expr, *process(clauses))
        end
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

        values = handle_argument_list values

        truepart = unwrap_nil process truepart

        s(s(:when,
            *values,
            truepart),
          *falsepart)
      end

      def process_right_assign(exp)
        _, pattern, = exp.shift 4
        pattern = handle_pattern(pattern)
        s(:right_assign, pattern)
      end

      def process_in(exp)
        _, pattern, truepart, falsepart = exp.shift 4

        falsepart = process(falsepart)
        falsepart = [nil] if falsepart.nil?
        pattern = handle_pattern(pattern)

        s(s(:in_pattern, pattern, nil, process(truepart)),
          *falsepart)
      end

      def process_else(exp)
        _, body = exp.shift 2
        process(body)
      end

      def process_aryptn(exp)
        _, _, body, rest, = exp.shift 5

        elements = body.map { |it| handle_pattern(it) }
        if rest
          rest = s(:match_rest, handle_pattern(rest))
          elements << rest
        end
        s(:array_pattern, *elements)
      end

      def process_hshptn(exp)
        _, _, body, = exp.shift 4

        elements = body.map do |key, value|
          if value
            s(:pair, process(key), handle_pattern(value))
          else
            handle_pattern(key)
          end
        end
        s(:hash_pattern, *elements)
      end

      private

      def handle_condition(cond)
        cond = process(cond)
        case cond.sexp_type
        when :regexp
          s(:match_current_line, cond)
        when :irange
          s(:iflipflop, *cond[1..])
        when :erange
          s(:eflipflop, *cond[1..])
        else
          cond
        end
      end

      def handle_consequent(exp)
        unwrap_nil process(exp) if exp
      end

      def handle_pattern(exp)
        pattern = process(exp)
        case pattern.sexp_type
        when :lvar, :sym
          @local_variables << pattern[1]
          pattern.sexp_type = :match_var
        end
        pattern
      end
    end
  end
end
