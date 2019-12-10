# frozen_string_literal: true

module RipperParser
  module SexpHandlers
    # Utility methods used in several of the sexp handler modules
    module HelperMethods
      def extract_node_symbol_with_position(exp)
        _, ident, pos = exp.shift 3
        return ident.to_sym, pos
      end

      def extract_node_symbol(exp)
        return nil if exp.nil?

        _, ident, = exp.shift 3
        ident.to_sym
      end

      def with_position(pos, exp = nil)
        (line,) = pos
        exp = yield if exp.nil?
        with_line_number line, exp
      end

      def with_line_number(line, exp)
        exp.line = line
        exp
      end

      def with_position_from_node_symbol(exp)
        sym, pos = extract_node_symbol_with_position exp
        with_position(pos, yield(sym))
      end

      def generic_add_star(exp)
        _, args, splatarg, *rest = shift_all exp
        items = process args
        items.push s(:splat, process(splatarg))
        items.push(*map_process_list(rest))
      end

      def reject_void_stmt(body)
        body.reject { |sub_exp| sub_exp.sexp_type == :void_stmt }
      end

      def map_process_list_compact(list)
        reject_void_stmt map_process_list list
      end

      def map_process_list_nils(list)
        map_process_list(list).map do |sub_exp|
          if sub_exp.sexp_type == :void_stmt
            nil
          else
            sub_exp
          end
        end
      end

      def map_process_list(list)
        list.map { |exp| process(exp) }
      end

      def unwrap_nil(exp)
        if exp.sexp_type == :void_stmt
          nil
        else
          exp
        end
      end

      def nil_if_empty(block)
        case block.length
        when 0
          nil
        else
          block
        end
      end

      def safe_unwrap_void_stmt(exp)
        unwrap_nil(exp) || s()
      end

      def unwrap_begin(exp)
        if exp.sexp_type == :begin
          exp[1]
        else
          exp
        end
      end

      def handle_argument_list(exp)
        process(exp).tap(&:shift)
      end

      def shift_all(exp)
        [].tap do |result|
          result << exp.shift until exp.empty?
        end
      end
    end
  end
end
