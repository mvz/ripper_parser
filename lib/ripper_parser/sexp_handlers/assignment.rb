# frozen_string_literal: true

module RipperParser
  module SexpHandlers
    # Sexp handlers for assignments
    module Assignment
      def process_assign(exp)
        _, lvalue, value = exp.shift 3
        lvalue = process(lvalue)
        value = process(value)
        value.sexp_type = :array if value.sexp_type == :mrhs

        with_line_number(lvalue.line,
                         create_regular_assignment_sub_type(lvalue, value))
      end

      def process_massign(exp)
        _, left, right = exp.shift 3
        left = process left
        right = process right
        right.sexp_type = :array if right.sexp_type == :mrhs

        s(:masgn, left, right)
      end

      def process_mrhs_new_from_args(exp)
        _, inner, last = exp.shift 3
        result = process(inner)
        result.sexp_type = :mrhs
        result.push process(last) if last
        result
      end

      def process_mrhs_add_star(exp)
        generic_add_star exp
      end

      def process_mlhs_add_star(exp)
        _, args, splatarg = exp.shift 3
        items = process args

        splat = process(splatarg)
        splat_item = if splat.nil?
                       s(:splat)
                     else
                       s(:splat, create_valueless_assignment_sub_type(splat))
                     end

        items << splat_item
      end

      def process_mlhs_add_post(exp)
        _, base, rest = exp.shift 3
        items = process(base)
        rest = process(rest)
        items.push(*rest.sexp_body)
      end

      def process_mlhs_paren(exp)
        _, contents = exp.shift 2

        process(contents)
      end

      def process_mlhs(exp)
        _, *rest = shift_all exp

        items = map_process_list(rest)
        s(:mlhs, *create_multiple_assignment_sub_types(items))
      end

      def process_opassign(exp)
        _, lvalue, operator, value = exp.shift 4

        lvalue = process(lvalue)
        value = process(value)
        operator = operator[1].delete("=").to_sym

        create_operator_assignment_sub_type lvalue, value, operator
      end

      private

      def create_multiple_assignment_sub_types(sexp_list)
        sexp_list.map! do |item|
          create_valueless_assignment_sub_type item
        end
      end

      def create_valueless_assignment_sub_type(item)
        item = with_line_number(item.line,
                                create_regular_assignment_sub_type(item, nil))
        item.pop
        item
      end

      OPERATOR_ASSIGNMENT_MAP = {
        '||': :or_asgn,
        '&&': :and_asgn
      }.freeze

      def create_operator_assignment_sub_type(lvalue, value, operator)
        lvalue = case lvalue.sexp_type
                 when :aref_field
                   _, arr, arglist = lvalue
                   s(:indexasgn, arr, *arglist.sexp_body)
                 when :field
                   _, obj, _, (_, field) = lvalue
                   s(:send, obj, field)
                 else
                   create_partial_assignment_sub_type(lvalue)
                 end

        if (mapped = OPERATOR_ASSIGNMENT_MAP[operator])
          s(mapped, lvalue, value)
        else
          s(:op_asgn, lvalue, operator, value)
        end
      end

      def create_regular_assignment_sub_type(lvalue, value)
        case lvalue.sexp_type
        when :aref_field
          _, arr, arglist = lvalue
          arglist << value
          arglist.shift
          s(:indexasgn, arr, *arglist)
        when :field
          _, obj, _, (_, field) = lvalue
          s(:send, obj, :"#{field}=", value)
        else
          create_assignment_sub_type lvalue, value
        end
      end

      ASSIGNMENT_SUB_TYPE_MAP = {
        ivar: :ivasgn,
        const: :casgn,
        lvar: :lvasgn,
        cvar: :cvasgn,
        gvar: :gvasgn
      }.freeze

      def create_assignment_sub_type(lvalue, value)
        s(map_assignment_lvalue_type(lvalue.sexp_type), *lvalue.sexp_body, value)
      end

      def create_partial_assignment_sub_type(lvalue)
        s(map_assignment_lvalue_type(lvalue.sexp_type), *lvalue.sexp_body)
      end

      def map_assignment_lvalue_type(type)
        ASSIGNMENT_SUB_TYPE_MAP[type] ||
          type
      end
    end
  end
end
