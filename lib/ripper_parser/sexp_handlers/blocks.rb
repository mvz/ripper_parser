# frozen_string_literal: true

module RipperParser
  module SexpHandlers
    # Sexp handlers for blocks and related constructs
    module Blocks
      def process_method_add_block(exp)
        _, call, block = exp.shift 3
        block = process(block)
        _, args, stmt = block
        call = process(call)
        stmts = stmt.first || s()
        make_iter call, args, stmts
      end

      def process_brace_block(exp)
        handle_generic_block exp
      end

      def process_do_block(exp)
        handle_generic_block exp
      end

      def process_params(exp)
        _, normal, defaults, splat, rest, kwargs, doublesplat, block = exp.shift 8

        args = []
        args += handle_normal_arguments normal
        args += handle_default_arguments defaults
        args += handle_splat splat
        args += handle_normal_arguments rest
        args += handle_kwargs kwargs
        args += handle_double_splat doublesplat
        args += handle_block_argument block

        s(:args, *args)
      end

      def process_kwrest_param(exp)
        _, sym, = exp.shift 3
        process(sym)
      end

      def process_block_var(exp)
        _, args, = exp.shift 3

        args = process(args)

        args = convert_special_args args
        case args.sexp_body.length
        when 1
          child = args.sexp_body.first
          child.sexp_type = :procarg0 if child.sexp_type == :arg
        when 2
          args.pop if args.sexp_body.last.sexp_type == :zerosplat
        end
        args
      end

      def process_begin(exp)
        _, body = exp.shift 2

        body = process(body)

        return s(:kwbegin) if body.empty?

        if body.sexp_type == :begin
          s(:kwbegin, *body.sexp_body)
        else
          s(:kwbegin, body)
        end
      end

      def process_rescue(exp)
        _, eclass, evar, block, after = exp.shift 5
        rescue_block = unwrap_nil process block

        capture = if eclass
                    if eclass.first.is_a? Symbol
                      eclass = process(eclass)
                      body = eclass.sexp_body
                      s(:array, *body)
                    else
                      s(:array, process(eclass[0]))
                    end
                  end

        assignment = create_partial_assignment_sub_type(process(evar)) if evar
        after = after ? process(after) : []
        s(
          s(:resbody, capture, assignment, rescue_block),
          *after)
      end

      def process_bodystmt(exp)
        _, main, rescue_block, else_block, ensure_block = exp.shift 5

        body = s()

        main = wrap_in_begin map_process_list_compact main.sexp_body
        body << main

        if rescue_block
          body.push(*process(rescue_block))
          body << process(else_block)
          body = s(s(:rescue, *body))
        elsif else_block
          body << s(:begin, process(else_block))
        end

        if ensure_block
          ensure_block = process ensure_block
          body << (ensure_block.empty? ? nil : ensure_block)
          body = s(s(:ensure, *body))
        end

        wrap_in_begin(body) || s()
      end

      def process_rescue_mod(exp)
        _, scary, safe = exp.shift 3
        s(:rescue, process(scary), s(:resbody, nil, nil, process(safe)), nil)
      end

      def process_ensure(exp)
        _, block = exp.shift 2
        safe_unwrap_void_stmt process(block)
      end

      def process_next(exp)
        _, args = exp.shift 2
        args = handle_argument_list(args)
        s(:next, *args)
      end

      def process_break(exp)
        _, args = exp.shift 2
        args = handle_argument_list(args)
        s(:break, *args)
      end

      def process_lambda(exp)
        _, args, statements = exp.shift 3
        args = convert_special_args(process(args))
        make_iter(s(:lambda),
                  args,
                  safe_unwrap_void_stmt(process(statements)))
      end

      private

      def handle_generic_block(exp)
        type, args, stmts = exp.shift 3
        args = process(args)
        kwrest = kwrest_param(args) if args
        body = with_kwrest(kwrest) { process(stmts) }
        s(type, args, s(unwrap_nil(body)))
      end

      def handle_normal_arguments(normal)
        return [] unless normal

        map_process_list normal
      end

      def handle_default_arguments(defaults)
        return [] unless defaults

        defaults.map { |sym, val| s(:lvasgn, process(sym)[1], process(val)) }
      end

      def handle_splat(splat)
        if splat == 0
          [s(:zerosplat)]
        elsif splat
          [process(splat)]
        else
          []
        end
      end

      def handle_kwargs(kwargs)
        return [] unless kwargs

        kwargs.map do |sym, val|
          symbol = process(sym)[1]
          if val
            s(:kwoptarg, symbol, process(val))
          else
            s(:kwarg, symbol)
          end
        end
      end

      def handle_double_splat(doublesplat)
        return [] unless doublesplat

        [s(:dsplat, process(doublesplat))]
      end

      def handle_block_argument(block)
        return [] unless block

        [process(block)]
      end

      def make_iter(call, args, stmt)
        args ||= s(:args)
        if stmt.empty?
          s(:block, call, args, nil)
        else
          s(:block, call, args, stmt)
        end
      end

      def wrap_in_begin(statements)
        case statements.length
        when 0
          nil
        when 1
          statements.first
        else
          s(:begin, *statements)
        end
      end
    end
  end
end
