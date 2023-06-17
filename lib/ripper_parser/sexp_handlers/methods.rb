# frozen_string_literal: true

module RipperParser
  module SexpHandlers
    # Sexp handers for method definitions and related constructs
    module Methods
      def process_def(exp)
        _, ident, params, body, pos = exp.shift 5

        ident, = extract_node_symbol_with_position ident

        params = convert_special_args(process(params))
        kwrest = kwrest_param(params)
        body = with_new_lvar_scope(kwrest) { method_body(body) }

        with_position(pos, s(:def, ident, params, body))
      end

      def process_defs(exp)
        _, receiver, _, method, params, body, = exp.shift 7

        params = convert_special_args(process(params))
        kwrest = kwrest_param(params)
        body = with_new_lvar_scope(kwrest) { method_body(body) }

        receiver = unwrap_begin process(receiver)

        s(:defs,
          receiver,
          extract_node_symbol(method),
          params, body)
      end

      def process_return(exp)
        _, arglist = exp.shift 2
        s(:return, *handle_argument_list(arglist))
      end

      def process_return0(exp)
        _ = exp.shift
        s(:return)
      end

      def process_yield(exp)
        _, arglist = exp.shift 2
        s(:yield, *handle_argument_list(arglist))
      end

      def process_yield0(exp)
        _ = exp.shift
        s(:yield)
      end

      def process_undef(exp)
        _, args = exp.shift 2

        s(:undef, *map_process_list(args))
      end

      def process_alias(exp)
        _, left, right = exp.shift 3

        s(:alias, process(left), process(right))
      end

      private

      def method_body(exp)
        nil_if_empty process(exp)
      end

      SPECIAL_ARG_MARKER = {
        splat: :restarg,
        dsplat: :kwrestarg
      }.freeze

      def convert_special_args(args)
        return s(:args) if args.nil?

        args.line ||= args.sexp_body.first&.line
        args.sexp_body = args.sexp_body.map { |item| convert_argument item }
        args
      end

      def convert_argument(item)
        case item.sexp_type
        when :lvar
          s(:arg, item[1])
        when :mlhs
          s(:mlhs, *item.sexp_body.map { |it| convert_argument it })
        when :lvasgn
          if item.length == 2
            s(:arg, item[1])
          else
            s(:optarg, *item.sexp_body)
          end
        when :blockarg
          s(:blockarg, extract_node_symbol(item[1]))
        when *SPECIAL_ARG_MARKER.keys
          convert_marked_argument item
        when :args_forward
          s(:forward_arg)
        else
          item
        end
      end

      def convert_marked_argument(item)
        type = SPECIAL_ARG_MARKER[item.sexp_type]
        name = extract_node_symbol item[1]
        if name && name != :''
          s(type, name)
        else
          s(type)
        end
      end

      def kwrest_param(params)
        found = params.sexp_body.find { |param| param.sexp_type == :kwrestarg }
        found[1] if found
      end

      def with_new_lvar_scope(extra_variable)
        old_lvars = @local_variables.dup
        @local_variables.push extra_variable if extra_variable
        result = yield
        @local_variables = old_lvars
        result
      end
    end
  end
end
