# frozen_string_literal: true

module RipperParser
  module SexpHandlers
    # Sexp handlers for method calls
    module MethodCalls
      def process_method_add_arg(exp)
        _, call, parens = exp.shift 3
        call = process(call)
        parens = process(parens)
        parens.shift
        parens.each do |arg|
          call << arg
        end
        call
      end

      def process_args_add_block(exp)
        _, regular, block = exp.shift 3
        args = process(regular)
        args << s(:block_pass, process(block)) if block
        s(:arglist, *args.sexp_body)
      end

      def process_args_add_star(exp)
        generic_add_star exp
      end

      def process_arg_paren(exp)
        _, args = exp.shift 2
        return s(:arglist) if args.nil?
        return s(:args, s(:forwarded_args)) if args == s(:args_forward)

        args = process(args)
        last_arg = args.sexp_body.last
        last_arg.sexp_type = :forwarded_args if last_arg.sexp_type == :args_forward

        args
      end

      # Handle implied hashes, such as at the end of argument lists.
      def process_bare_assoc_hash(exp)
        _, elems = exp.shift 2
        s(:kwargs, *map_process_list(elems))
      end

      CALL_OP_MAP = {
        ".": :send,
        "::": :send,
        "&.": :csend
      }.freeze

      def process_call(exp)
        _, receiver, op, ident = exp.shift 4
        type = map_call_op op
        case ident
        when :call
          s(type, process(receiver), :call)
        else
          with_position_from_node_symbol(ident) do |method|
            s(type, process(receiver), method)
          end
        end
      end

      def process_command(exp)
        _, ident, arglist = exp.shift 3
        with_position_from_node_symbol(ident) do |method|
          args = handle_argument_list(arglist)
          s(:send, nil, method, *args)
        end
      end

      def process_command_call(exp)
        _, receiver, op, ident, arguments = exp.shift 5
        type = map_call_op op
        with_position_from_node_symbol(ident) do |method|
          args = handle_argument_list(arguments)
          s(type, process(receiver), method, *args)
        end
      end

      def process_vcall(exp)
        _, ident = exp.shift 2
        with_position_from_node_symbol(ident) do |method|
          if @local_variables.include? method
            s(:lvar, method)
          else
            s(:send, nil, method)
          end
        end
      end

      def process_fcall(exp)
        _, ident = exp.shift 2
        with_position_from_node_symbol(ident) do |method|
          s(:send, nil, method)
        end
      end

      def process_super(exp)
        _, args = exp.shift 2
        args = process(args)
        args.shift
        s(:super, *args)
      end

      def process_aref(exp)
        _, coll, idx = exp.shift 3

        coll = process(coll)
        idx = process(idx) || s(:arglist)
        idx.shift
        s(:index, coll, *idx)
      end

      private

      def map_call_op(call_op)
        call_op = call_op.sexp_body.first.to_sym if call_op.is_a? Sexp
        CALL_OP_MAP.fetch(call_op)
      end
    end
  end
end
