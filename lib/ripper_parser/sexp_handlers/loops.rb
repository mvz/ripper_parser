# frozen_string_literal: true

module RipperParser
  module SexpHandlers
    # Sexp handlers for loops
    module Loops
      def process_until(exp)
        handle_conditional_loop :until, exp
      end

      def process_until_mod(exp)
        handle_conditional_loop_mod :until, :until_post, exp
      end

      def process_while(exp)
        handle_conditional_loop :while, exp
      end

      def process_while_mod(exp)
        handle_conditional_loop_mod :while, :while_post, exp
      end

      def process_for(exp)
        _, var, coll, block = exp.shift 4
        coll = process(coll)
        var = process(var)

        assgn = if var.sexp_type == :mlhs
                  var
                else
                  s(:lvasgn, var[1])
                end
        block = unwrap_nil process(block)
        s(:for, assgn, coll, block)
      end

      private

      def check_at_start?(block)
        block.sexp_type != :begin
      end

      def handle_conditional_loop(type, exp)
        _, cond, body = exp.shift 3

        s(type, process(cond), unwrap_nil(process(body)))
      end

      def handle_conditional_loop_mod(type, post_type, exp)
        _, cond, body = exp.shift 3

        type = post_type unless check_at_start?(body)
        s(type, process(cond), process(body))
      end

      def construct_conditional_loop(type, cond, body)
        s(type, cond, body)
      end
    end
  end
end
