# frozen_string_literal: true

require File.expand_path("../../test_helper.rb", File.dirname(__FILE__))

describe RipperParser::Parser do
  describe "#parse" do
    describe "for regular if" do
      it "works with a single statement" do
        _("if foo; bar; end")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar),
                               nil)
      end

      it "works with multiple statements" do
        _("if foo; bar; baz; end")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               s(:begin,
                                 s(:send, nil, :bar),
                                 s(:send, nil, :baz)),
                               nil)
      end

      it "works with zero statements" do
        _("if foo; end")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               nil,
                               nil)
      end

      it "works with a begin..end block" do
        _("if foo; begin; bar; end; end")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               s(:kwbegin, s(:send, nil, :bar)),
                               nil)
      end

      it "works with an else clause" do
        _("if foo; bar; else; baz; end")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar),
                               s(:send, nil, :baz))
      end

      it "works with an empty main clause" do
        _("if foo; else; bar; end")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               nil,
                               s(:send, nil, :bar))
      end

      it "works with an empty else clause" do
        _("if foo; bar; else; end")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar),
                               nil)
      end

      it "handles a negative condition correctly" do
        _("if not foo; bar; end")
          .must_be_parsed_as s(:if,
                               s(:send, s(:send, nil, :foo), :!),
                               s(:send, nil, :bar),
                               nil)
      end

      it "handles bare regex literal in condition" do
        _("if /foo/; bar; end")
          .must_be_parsed_as s(:if,
                               s(:match_current_line,
                                 s(:regexp,
                                   s(:str, "foo"),
                                   s(:regopt))),
                               s(:send, nil, :bar), nil)
      end

      it "handles interpolated regex in condition" do
        _('if /#{foo}/; bar; end')
          .must_be_parsed_as s(:if,
                               s(:match_current_line,
                                 s(:regexp,
                                   s(:begin,
                                     s(:send, nil, :foo)),
                                   s(:regopt))),
                               s(:send, nil, :bar), nil)
      end

      it "handles block conditions" do
        _("if (foo; bar); baz; end")
          .must_be_parsed_as s(:if,
                               s(:begin,
                                 s(:send, nil, :foo),
                                 s(:send, nil, :bar)),
                               s(:send, nil, :baz),
                               nil)
      end

      it "converts :dot2 to :iflipflop" do
        _("if foo..bar; baz; end")
          .must_be_parsed_as s(:if,
                               s(:iflipflop,
                                 s(:send, nil, :foo),
                                 s(:send, nil, :bar)),
                               s(:send, nil, :baz), nil)
      end

      it "converts :dot3 to :eflipflop" do
        _("if foo...bar; baz; end")
          .must_be_parsed_as s(:if,
                               s(:eflipflop,
                                 s(:send, nil, :foo),
                                 s(:send, nil, :bar)),
                               s(:send, nil, :baz), nil)
      end

      it "handles negative match operator" do
        _("if foo !~ bar; baz; else; qux; end")
          .must_be_parsed_as s(:if,
                               s(:send, s(:send, nil, :foo), :!~, s(:send, nil, :bar)),
                               s(:send, nil, :baz),
                               s(:send, nil, :qux))
      end

      it "works with begin..end block in condition" do
        _("if begin foo end; bar; end")
          .must_be_parsed_as s(:if,
                               s(:kwbegin,
                                 s(:send, nil, :foo)),
                               s(:send, nil, :bar), nil)
      end

      it "works with special conditions inside begin..end block" do
        _("if begin foo..bar end; baz; end")
          .must_be_parsed_as s(:if,
                               s(:kwbegin,
                                 s(:irange, s(:send, nil, :foo), s(:send, nil, :bar))),
                               s(:send, nil, :baz),
                               nil)
      end

      it "works with assignment in the condition" do
        _("if foo = bar; baz; end")
          .must_be_parsed_as s(:if,
                               s(:lvasgn, :foo,
                                 s(:send, nil, :bar)),
                               s(:send, nil, :baz), nil)
      end

      it "works with bracketed assignment in the condition" do
        _("if (foo = bar); baz; end")
          .must_be_parsed_as s(:if,
                               s(:begin,
                                 s(:lvasgn, :foo,
                                   s(:send, nil, :bar))),
                               s(:send, nil, :baz), nil)
      end
    end

    describe "for postfix if" do
      it "works with a simple condition" do
        _("foo if bar")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :bar),
                               s(:send, nil, :foo),
                               nil)
      end

      it "handles negative conditions" do
        _("foo if not bar")
          .must_be_parsed_as s(:if,
                               s(:send, s(:send, nil, :bar), :!),
                               s(:send, nil, :foo),
                               nil)
      end

      it "handles bare regex literal in condition" do
        _("foo if /bar/")
          .must_be_parsed_as s(:if,
                               s(:match_current_line,
                                 s(:regexp, s(:str, "bar"), s(:regopt))),
                               s(:send, nil, :foo),
                               nil)
      end

      it "handles interpolated regex in condition" do
        _('foo if /#{bar}/')
          .must_be_parsed_as s(:if,
                               s(:match_current_line,
                                 s(:regexp,
                                   s(:begin,
                                     s(:send, nil, :bar)),
                                   s(:regopt))),
                               s(:send, nil, :foo), nil)
      end

      it "handles negative match operator" do
        _("baz if foo !~ bar")
          .must_be_parsed_as s(:if,
                               s(:send, s(:send, nil, :foo), :!~, s(:send, nil, :bar)),
                               s(:send, nil, :baz),
                               nil)
      end

      it "works with begin..end block in condition" do
        _("foo if begin bar end")
          .must_be_parsed_as s(:if,
                               s(:kwbegin,
                                 s(:send, nil, :bar)),
                               s(:send, nil, :foo), nil)
      end
    end

    describe "for regular unless" do
      it "works with a single statement" do
        _("unless bar; foo; end")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :bar),
                               nil,
                               s(:send, nil, :foo))
      end

      it "works with multiple statements" do
        _("unless foo; bar; baz; end")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               nil,
                               s(:begin,
                                 s(:send, nil, :bar),
                                 s(:send, nil, :baz)))
      end

      it "works with zero statements" do
        _("unless foo; end")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               nil,
                               nil)
      end

      it "works with an else clause" do
        _("unless foo; bar; else; baz; end")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               s(:send, nil, :baz),
                               s(:send, nil, :bar))
      end

      it "works with an empty main clause" do
        _("unless foo; else; bar; end")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar),
                               nil)
      end

      it "works with an empty else block" do
        _("unless foo; bar; else; end")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               nil,
                               s(:send, nil, :bar))
      end

      it "handles bare regex literal in condition" do
        _("unless /foo/; bar; end")
          .must_be_parsed_as s(:if,
                               s(:match_current_line,
                                 s(:regexp,
                                   s(:str, "foo"),
                                   s(:regopt))),
                               nil,
                               s(:send, nil, :bar))
      end

      it "handles interpolated regex in condition" do
        _('unless /#{foo}/; bar; end')
          .must_be_parsed_as s(:if,
                               s(:match_current_line,
                                 s(:regexp, s(:begin, s(:send, nil, :foo)), s(:regopt))),
                               nil,
                               s(:send, nil, :bar))
      end

      it "handles negative match operator" do
        _("unless foo !~ bar; baz; else; qux; end")
          .must_be_parsed_as s(:if,
                               s(:send, s(:send, nil, :foo), :!~, s(:send, nil, :bar)),
                               s(:send, nil, :qux),
                               s(:send, nil, :baz))
      end
    end

    describe "for postfix unless" do
      it "works with a simple condition" do
        _("foo unless bar")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :bar),
                               nil,
                               s(:send, nil, :foo))
      end

      it "handles bare regex literal in condition" do
        _("foo unless /bar/")
          .must_be_parsed_as s(:if,
                               s(:match_current_line,
                                 s(:regexp,
                                   s(:str, "bar"),
                                   s(:regopt))),
                               nil,
                               s(:send, nil, :foo))
      end

      it "handles interpolated regex in condition" do
        _('foo unless /#{bar}/')
          .must_be_parsed_as s(:if,
                               s(:match_current_line,
                                 s(:regexp,
                                   s(:begin,
                                     s(:send, nil, :bar)),
                                   s(:regopt))),
                               nil,
                               s(:send, nil, :foo))
      end

      it "handles negative match operator" do
        _("baz unless foo !~ bar")
          .must_be_parsed_as s(:if,
                               s(:send, s(:send, nil, :foo), :!~, s(:send, nil, :bar)),
                               nil,
                               s(:send, nil, :baz))
      end
    end

    describe "for elsif" do
      it "works with a single statement" do
        _("if foo; bar; elsif baz; qux; end")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar),
                               s(:if,
                                 s(:send, nil, :baz),
                                 s(:send, nil, :qux),
                                 nil))
      end

      it "works with an empty consequesnt" do
        _("if foo; bar; elsif baz; end")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar),
                               s(:if,
                                 s(:send, nil, :baz),
                                 nil,
                                 nil))
      end

      it "works with an empty else" do
        _("if foo; bar; elsif baz; qux; else; end")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar),
                               s(:if,
                                 s(:send, nil, :baz),
                                 s(:send, nil, :qux),
                                 nil))
      end

      it "handles a negative condition correctly" do
        _("if foo; bar; elsif not baz; qux; end")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar),
                               s(:if,
                                 s(:send, s(:send, nil, :baz), :!),
                                 s(:send, nil, :qux), nil))
      end

      it "replaces :dot2 with :iflipflop" do
        _("if foo; bar; elsif baz..qux; quuz; end")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar),
                               s(:if,
                                 s(:iflipflop, s(:send, nil, :baz), s(:send, nil, :qux)),
                                 s(:send, nil, :quuz), nil))
      end

      it "does not rewrite the negative match operator" do
        _("if foo; bar; elsif baz !~ qux; quuz; end")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar),
                               s(:if,
                                 s(:send,
                                   s(:send, nil, :baz),
                                   :!~,
                                   s(:send, nil, :qux)),
                                 s(:send, nil, :quuz),
                                 nil))
      end

      it "works with begin..end block in condition" do
        _("if foo; bar; elsif begin baz end; qux; end")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar),
                               s(:if,
                                 s(:kwbegin,
                                   s(:send, nil, :baz)),
                                 s(:send, nil, :qux),
                                 nil))
      end
    end

    describe "for case block" do
      it "works with a single when clause" do
        _("case foo; when bar; baz; end")
          .must_be_parsed_as s(:case,
                               s(:send, nil, :foo),
                               s(:when,
                                 s(:send, nil, :bar),
                                 s(:send, nil, :baz)),
                               nil)
      end

      it "works with multiple when clauses" do
        _("case foo; when bar; baz; when qux; quux; end")
          .must_be_parsed_as s(:case,
                               s(:send, nil, :foo),
                               s(:when,
                                 s(:send, nil, :bar),
                                 s(:send, nil, :baz)),
                               s(:when,
                                 s(:send, nil, :qux),
                                 s(:send, nil, :quux)),
                               nil)
      end

      it "works with multiple statements in the when block" do
        _("case foo; when bar; baz; qux; end")
          .must_be_parsed_as s(:case,
                               s(:send, nil, :foo),
                               s(:when,
                                 s(:send, nil, :bar),
                                 s(:begin,
                                   s(:send, nil, :baz),
                                   s(:send, nil, :qux))),
                               nil)
      end

      it "works with an else clause" do
        _("case foo; when bar; baz; else; qux; end")
          .must_be_parsed_as s(:case,
                               s(:send, nil, :foo),
                               s(:when,
                                 s(:send, nil, :bar),
                                 s(:send, nil, :baz)),
                               s(:send, nil, :qux))
      end

      it "works with multiple statements in the else block" do
        _("case foo; when bar; baz; else; qux; quuz end")
          .must_be_parsed_as s(:case,
                               s(:send, nil, :foo),
                               s(:when,
                                 s(:send, nil, :bar),
                                 s(:send, nil, :baz)),
                               s(:begin,
                                 s(:send, nil, :qux),
                                 s(:send, nil, :quuz)))
      end

      it "works with an empty when block" do
        _("case foo; when bar; end")
          .must_be_parsed_as s(:case,
                               s(:send, nil, :foo),
                               s(:when, s(:send, nil, :bar), nil),
                               nil)
      end

      it "works with an empty else block" do
        _("case foo; when bar; baz; else; end")
          .must_be_parsed_as s(:case,
                               s(:send, nil, :foo),
                               s(:when,
                                 s(:send, nil, :bar),
                                 s(:send, nil, :baz)),
                               nil)
      end

      it "works with a splat in the when clause" do
        _("case foo; when *bar; baz; end")
          .must_be_parsed_as s(:case,
                               s(:send, nil, :foo),
                               s(:when,
                                 s(:splat, s(:send, nil, :bar)),
                                 s(:send, nil, :baz)),
                               nil)
      end
    end
  end
end
