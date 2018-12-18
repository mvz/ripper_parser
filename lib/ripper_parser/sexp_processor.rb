require 'sexp_processor'
require 'ripper_parser/sexp_handlers'
require 'ripper_parser/unescape'

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

      @processors[:@tstring_content] = :process_at_tstring_content

      @filename = filename

      @errors = []

      @in_method_body = false
      @kwrest = nil
    end

    include SexpHandlers

    def process_program(exp)
      _, content = exp.shift 2

      process content
    end

    def process_module(exp)
      _, const_ref, body = exp.shift 3
      const, line = const_ref_to_const_with_line_number const_ref
      with_line_number(line,
                       s(:module, const, class_or_module_body(body)))
    end

    def process_class(exp)
      _, const_ref, parent, body = exp.shift 4
      const, line = const_ref_to_const_with_line_number const_ref
      parent = process(parent)
      with_line_number(line,
                       s(:class, const, parent, class_or_module_body(body)))
    end

    def process_sclass(exp)
      _, klass, block = exp.shift 3
      s(:sclass, process(klass), class_or_module_body(block))
    end

    def process_stmts(exp)
      _, *statements = shift_all(exp)
      statements = map_process_list_compact statements
      case statements.count
      when 0
        s(:void_stmt)
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
      s(:cbase, extract_node_symbol(ref))
    end

    def process_top_const_field(exp)
      s(:const, process_top_const_ref(exp))
    end

    def process_paren(exp)
      _, body = exp.shift 2
      if body.sexp_type == :stmts
        result = process body
        case result.sexp_type
        when :void_stmt
          s(:nil)
        when :begin
          result
        else
          s(:begin, result)
        end
      else
        result = process body
        if result.sexp_type == :void_stmt
          s(:nil)
        else
          result
        end
      end
    end

    def process_comment(exp)
      _, comment, inner = exp.shift 3
      sexp = process(inner)
      sexp.comments = comment
      sexp
    end

    def process_BEGIN(exp)
      _, body = exp.shift 2
      body = map_process_list_nils body.sexp_body
      s(:preexe, *body)
    end

    def process_END(exp)
      _, body = exp.shift 2
      body = map_process_list_nils body.sexp_body
      s(:postexe, *body)
    end

    # number literals
    def process_at_int(exp)
      _, val, pos = exp.shift 3
      with_position(pos, s(:int, Integer(val)))
    end

    def process_at_float(exp)
      _, val, pos = exp.shift 3
      with_position(pos, s(:float, val.to_f))
    end

    def process_at_rational(exp)
      _, val, pos = exp.shift 3
      with_position(pos, s(:rational, val.to_r))
    end

    # character literals
    def process_at_CHAR(exp)
      _, val, pos = exp.shift 3
      with_position(pos, s(:str, unescape(val[1..-1])))
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
               when :__ENCODING__
                 s(:const, s(:const, nil, :Encoding), :UTF_8)
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
      name = str[1..-1]
      with_position pos do
        if name =~ /[0-9]/
          s(:nth_ref, name.to_i)
        else
          s(:back_ref, name.to_sym)
        end
      end
    end

    private

    def const_ref_to_const_with_line_number(const_ref)
      const = process(const_ref)
      line = const.line
      return const, line
    end

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
