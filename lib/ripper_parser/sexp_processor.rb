# frozen_string_literal: true

require "sexp_processor"
require "ripper_parser/sexp_handlers"
require "ripper_parser/unescape"

module RipperParser
  # Processes the sexp created by Ripper to what Parser would produce.
  #
  # @api private
  class SexpProcessor < ::SexpProcessor
    include Unescape

    def initialize(filename: nil)
      super()

      @processors[:@int] = :process_at_int
      @processors[:@float] = :process_at_float
      @processors[:@rational] = :process_at_rational
      @processors[:@imaginary] = :process_at_imaginary
      @processors[:@CHAR] = :process_at_CHAR
      @processors[:@label] = :process_at_label

      @processors[:@const] = :process_at_const
      @processors[:@ident] = :process_at_ident
      @processors[:@cvar] = :process_at_cvar
      @processors[:@gvar] = :process_at_gvar
      @processors[:@ivar] = :process_at_ivar
      @processors[:@kw] = :process_at_kw
      @processors[:@op] = :process_at_op
      @processors[:@backref] = :process_at_backref
      @processors[:@period] = :process_at_period

      @processors[:@tstring_content] = :process_at_tstring_content

      @filename = filename

      @errors = []

      @local_variables = []
    end

    include SexpHandlers

    def process_program(exp)
      _, content = exp.shift 2

      process content
    end

    def process_module(exp)
      _, const_ref, body, pos = exp.shift 4
      const = process(const_ref)
      with_position(pos,
                    s(:module, const, class_or_module_body(body)))
    end

    def process_class(exp)
      _, const_ref, parent, body, pos = exp.shift 5
      const = process(const_ref)
      parent = process(parent)
      with_position(pos,
                    s(:class, const, parent, class_or_module_body(body)))
    end

    def process_sclass(exp)
      _, klass, block, pos = exp.shift 4
      with_position pos, s(:sclass, process(klass), class_or_module_body(block))
    end

    def process_stmts(exp)
      _, *statements = shift_all(exp)

      statements = map_process_list statements
      line = statements.first.line
      statements = reject_void_stmt statements
      case statements.count
      when 0
        s(:void_stmt).line(line)
      when 1
        statements.first
      else
        s(:begin, *statements)
      end
    end

    def process_var_ref(exp)
      _, contents = exp.shift 2
      process(contents)
    end

    def process_var_field(exp)
      _, contents = exp.shift 2
      process(contents)
    end

    def process_var_alias(exp)
      _, left, right = exp.shift 3
      s(:valias, left[1].to_sym, right[1].to_sym)
    end

    def process_void_stmt(exp)
      _, pos = exp.shift 2
      with_position pos, s(:void_stmt)
    end

    def process_const_path_ref(exp)
      _, left, right = exp.shift 3
      s(:const, process(left), extract_node_symbol(right))
    end

    def process_const_path_field(exp)
      s(:const, process_const_path_ref(exp))
    end

    def process_const_ref(exp)
      _, ref = exp.shift 3
      process(ref)
    end

    def process_top_const_ref(exp)
      _, ref = exp.shift 2
      s(:const, s(:cbase), extract_node_symbol(ref))
    end

    def process_top_const_field(exp)
      process_top_const_ref(exp)
    end

    def process_paren(exp)
      _, body = exp.shift 2

      has_nested_paren = body.sexp_type == :stmts && body[1].sexp_type == :paren
      result = process body
      case result.sexp_type
      when :void_stmt
        s(:nil)
      when :args, :arglist
        result
      when :begin
        if has_nested_paren
          s(:begin, result)
        else
          result
        end
      else
        s(:begin, result)
      end
    end

    def process_comment(exp)
      _, comment, inner = exp.shift 3
      sexp = process(inner)
      sexp.comments = comment
      sexp
    end

    def process_BEGIN(exp)
      _, body, pos = exp.shift 3
      body = map_process_list_nils body.sexp_body
      with_position pos, s(:preexe, *body)
    end

    def process_END(exp)
      _, body, pos = exp.shift 3
      body = map_process_list_nils body.sexp_body
      with_position pos, s(:postexe, *body)
    end

    def process_defined(exp)
      _, arg = exp.shift 2
      s(:defined?, process(arg))
    end

    def process_at_label(exp)
      _, val, pos = exp.shift 3
      with_position(pos, s(:sym, val.chop.to_sym))
    end

    # symbol-like sexps
    def process_at_const(exp)
      with_position_from_node_symbol(exp) do |ident|
        s(:const, nil, ident)
      end
    end

    def process_at_cvar(exp)
      make_identifier(:cvar, exp)
    end

    def process_at_gvar(exp)
      make_identifier(:gvar, exp)
    end

    def process_at_ivar(exp)
      make_identifier(:ivar, exp)
    end

    def process_at_ident(exp)
      make_identifier(:lvar, exp)
    end

    def process_at_op(exp)
      make_identifier(:op, exp)
    end

    def process_at_kw(exp)
      sym, pos = extract_node_symbol_with_position(exp)
      result = case sym
               when :__FILE__
                 s(:str, @filename)
               when :__LINE__
                 s(:int, pos[0])
               else
                 s(sym)
               end
      with_position(pos, result)
    end

    def process_at_backref(exp)
      _, str, pos = exp.shift 3
      name = str[1..]
      with_position pos do
        if /[0-9]/.match?(name)
          s(:nth_ref, name.to_i)
        else
          s(:back_ref, name.to_sym)
        end
      end
    end

    def process_at_period(exp)
      _, period, = exp.shift 3
      s(:period, period)
    end

    private

    def class_or_module_body(exp)
      nil_if_empty process(exp)
    end

    def make_identifier(type, exp)
      with_position_from_node_symbol(exp) do |ident|
        s(type, ident)
      end
    end
  end
end
