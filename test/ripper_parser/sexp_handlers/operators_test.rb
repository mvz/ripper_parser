# frozen_string_literal: true

require File.expand_path("../../test_helper.rb", File.dirname(__FILE__))

describe RipperParser::Parser do
  describe "#parse" do
    describe "for boolean operators" do
      it "handles :and" do
        _("foo and bar")
          .must_be_parsed_as s(:and,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar))
      end

      it "handles double :and" do
        _("foo and bar and baz")
          .must_be_parsed_as s(:and,
                               s(:and,
                                 s(:send, nil, :foo),
                                 s(:send, nil, :bar)),
                               s(:send, nil, :baz))
      end

      it "handles :or" do
        _("foo or bar")
          .must_be_parsed_as s(:or,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar))
      end

      it "handles double :or" do
        _("foo or bar or baz")
          .must_be_parsed_as s(:or,
                               s(:or,
                                 s(:send, nil, :foo),
                                 s(:send, nil, :bar)),
                               s(:send, nil, :baz))
      end

      it "handles :or after :and" do
        _("foo and bar or baz")
          .must_be_parsed_as s(:or,
                               s(:and,
                                 s(:send, nil, :foo),
                                 s(:send, nil, :bar)),
                               s(:send, nil, :baz))
      end

      it "handles :and after :or" do
        _("foo or bar and baz")
          .must_be_parsed_as s(:and,
                               s(:or,
                                 s(:send, nil, :foo),
                                 s(:send, nil, :bar)),
                               s(:send, nil, :baz))
      end

      it "converts :&& to :and" do
        _("foo && bar")
          .must_be_parsed_as s(:and,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar))
      end

      it "handles :|| after :&&" do
        _("foo && bar || baz")
          .must_be_parsed_as s(:or,
                               s(:and,
                                 s(:send, nil, :foo),
                                 s(:send, nil, :bar)),
                               s(:send, nil, :baz))
      end

      it "handles :&& after :||" do
        _("foo || bar && baz")
          .must_be_parsed_as s(:or,
                               s(:send, nil, :foo),
                               s(:and,
                                 s(:send, nil, :bar),
                                 s(:send, nil, :baz)))
      end

      it "handles :|| with parentheses" do
        _("(foo || bar) || baz")
          .must_be_parsed_as s(:or,
                               s(:begin,
                                 s(:or,
                                   s(:send, nil, :foo),
                                   s(:send, nil, :bar))),
                               s(:send, nil, :baz))
      end

      it "handles nested :|| with parentheses" do
        _("foo || (bar || baz) || qux")
          .must_be_parsed_as s(:or,
                               s(:or,
                                 s(:send, nil, :foo),
                                 s(:begin,
                                   s(:or,
                                     s(:send, nil, :bar),
                                     s(:send, nil, :baz)))),
                               s(:send, nil, :qux))
      end

      it "converts :|| to :or" do
        _("foo || bar")
          .must_be_parsed_as s(:or,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar))
      end

      it "handles triple :and" do
        _("foo and bar and baz and qux")
          .must_be_parsed_as s(:and,
                               s(:and,
                                 s(:and,
                                   s(:send, nil, :foo),
                                   s(:send, nil, :bar)),
                                 s(:send, nil, :baz)),
                               s(:send, nil, :qux))
      end

      it "handles triple :&&" do
        _("foo && bar && baz && qux")
          .must_be_parsed_as s(:and,
                               s(:and,
                                 s(:and,
                                   s(:send, nil, :foo),
                                   s(:send, nil, :bar)),
                                 s(:send, nil, :baz)),
                               s(:send, nil, :qux))
      end

      it "handles :!=" do
        _("foo != bar")
          .must_be_parsed_as s(:send,
                               s(:send, nil, :foo),
                               :!=,
                               s(:send, nil, :bar))
      end

      it "keeps :kwbegin for the first argument of a binary operator" do
        _("begin; bar; end + foo")
          .must_be_parsed_as s(:send,
                               s(:kwbegin, s(:send, nil, :bar)),
                               :+,
                               s(:send, nil, :foo))
      end

      it "keeps :kwbegin for the second argument of a binary operator" do
        _("foo + begin; bar; end")
          .must_be_parsed_as s(:send,
                               s(:send, nil, :foo),
                               :+,
                               s(:kwbegin, s(:send, nil, :bar)))
      end

      it "keeps :kwbegin for the first argument of a boolean operator" do
        _("begin; bar; end and foo")
          .must_be_parsed_as s(:and,
                               s(:kwbegin, s(:send, nil, :bar)),
                               s(:send, nil, :foo))
      end

      it "keeps :kwbegin for the second argument of a boolean operator" do
        _("foo and begin; bar; end")
          .must_be_parsed_as s(:and,
                               s(:send, nil, :foo),
                               s(:kwbegin, s(:send, nil, :bar)))
      end

      it "keeps :kwbegin for the first argument of a shift operator" do
        _("begin; bar; end << foo")
          .must_be_parsed_as s(:send,
                               s(:kwbegin, s(:send, nil, :bar)),
                               :<<,
                               s(:send, nil, :foo))
      end

      it "keeps :kwbegin for the second argument of a shift operator" do
        _("foo >> begin; bar; end")
          .must_be_parsed_as s(:send,
                               s(:send, nil, :foo),
                               :>>,
                               s(:kwbegin, s(:send, nil, :bar)))
      end
    end

    describe "for the range operator" do
      it "handles positive number literals" do
        _("1..2")
          .must_be_parsed_as s(:irange,
                               s(:int, 1),
                               s(:int, 2))
      end

      it "handles negative number literals" do
        _("-1..-2")
          .must_be_parsed_as s(:irange,
                               s(:int, -1),
                               s(:int, -2))
      end

      it "handles float literals" do
        _("1.0..2.0")
          .must_be_parsed_as s(:irange,
                               s(:float, 1.0),
                               s(:float, 2.0))
      end

      it "handles string literals" do
        _("'a'..'z'")
          .must_be_parsed_as s(:irange,
                               s(:str, "a"),
                               s(:str, "z"))
      end

      it "handles non-literal begin" do
        _("foo..3")
          .must_be_parsed_as s(:irange,
                               s(:send, nil, :foo),
                               s(:int, 3))
      end

      it "handles non-literal end" do
        _("3..foo")
          .must_be_parsed_as s(:irange,
                               s(:int, 3),
                               s(:send, nil, :foo))
      end

      it "handles non-literals" do
        _("foo..bar")
          .must_be_parsed_as s(:irange,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar))
      end

      it "handles parentheses" do
        _("(foo)..(bar)")
          .must_be_parsed_as s(:irange,
                               s(:begin, s(:send, nil, :foo)),
                               s(:begin, s(:send, nil, :bar)))
      end

      it "handles endless range literals" do
        skip "This Ruby version does not support endless ranges" if RUBY_VERSION < "2.6.0"
        _("1..")
          .must_be_parsed_as s(:irange, s(:int, 1), nil)
      end

      it "handles beginless range literals" do
        skip "This Ruby version does not support beginless ranges" if RUBY_VERSION < "2.7.0"
        _("..1")
          .must_be_parsed_as s(:irange, nil, s(:int, 1))
      end
    end

    describe "for the exclusive range operator" do
      it "handles positive number literals" do
        _("1...2")
          .must_be_parsed_as s(:erange,
                               s(:int, 1),
                               s(:int, 2))
      end

      it "handles negative number literals" do
        _("-1...-2")
          .must_be_parsed_as s(:erange,
                               s(:int, -1),
                               s(:int, -2))
      end

      it "handles float literals" do
        _("1.0...2.0")
          .must_be_parsed_as s(:erange,
                               s(:float, 1.0),
                               s(:float, 2.0))
      end

      it "handles string literals" do
        _("'a'...'z'")
          .must_be_parsed_as s(:erange,
                               s(:str, "a"),
                               s(:str, "z"))
      end

      it "handles non-literal begin" do
        _("foo...3")
          .must_be_parsed_as s(:erange,
                               s(:send, nil, :foo),
                               s(:int, 3))
      end

      it "handles non-literal end" do
        _("3...foo")
          .must_be_parsed_as s(:erange,
                               s(:int, 3),
                               s(:send, nil, :foo))
      end

      it "handles two non-literals" do
        _("foo...bar")
          .must_be_parsed_as s(:erange,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar))
      end

      it "handles parentheses" do
        _("(foo)...(bar)")
          .must_be_parsed_as s(:erange,
                               s(:begin, s(:send, nil, :foo)),
                               s(:begin, s(:send, nil, :bar)))
      end

      it "handles endless range literals" do
        skip "This Ruby version does not support endless ranges" if RUBY_VERSION < "2.6.0"
        _("1...")
          .must_be_parsed_as s(:erange, s(:int, 1), nil)
      end

      it "handles beginless range literals" do
        skip "This Ruby version does not support beginless ranges" if RUBY_VERSION < "2.7.0"
        _("...1")
          .must_be_parsed_as s(:erange, nil, s(:int, 1))
      end
    end

    describe "for unary operators" do
      it "handles unary minus with an integer literal" do
        _("- 1").must_be_parsed_as s(:send, s(:int, 1), :-@)
      end

      it "handles unary minus with a float literal" do
        _("- 3.14").must_be_parsed_as s(:send, s(:float, 3.14), :-@)
      end

      it "handles unary minus with a non-literal" do
        _("-foo")
          .must_be_parsed_as s(:send,
                               s(:send, nil, :foo),
                               :-@)
      end

      it "handles unary minus with a negative number literal" do
        _("- -1").must_be_parsed_as s(:send, s(:int, -1), :-@)
      end

      it "handles unary plus with a number literal" do
        _("+ 1").must_be_parsed_as s(:send, s(:int, 1), :+@)
      end

      it "handles unary plus with a non-literal" do
        _("+foo")
          .must_be_parsed_as s(:send,
                               s(:send, nil, :foo),
                               :+@)
      end

      it "handles unary !" do
        _("!foo")
          .must_be_parsed_as s(:send, s(:send, nil, :foo), :!)
      end

      it "converts :not to :!" do
        _("not foo")
          .must_be_parsed_as s(:send, s(:send, nil, :foo), :!)
      end

      it "handles unary ! with a number literal" do
        _("!1")
          .must_be_parsed_as s(:send, s(:int, 1), :!)
      end

      it "keeps :kwbegin for the argument" do
        _("- begin; foo; end")
          .must_be_parsed_as s(:send,
                               s(:kwbegin, s(:send, nil, :foo)),
                               :-@)
      end
    end

    describe "for the ternary operator" do
      it "works in the simple case" do
        _("foo ? bar : baz")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar),
                               s(:send, nil, :baz))
      end

      it "keeps :kwbegin for the first argument" do
        _("begin; foo; end ? bar : baz")
          .must_be_parsed_as s(:if,
                               s(:kwbegin, s(:send, nil, :foo)),
                               s(:send, nil, :bar),
                               s(:send, nil, :baz))
      end

      it "keeps :kwbegin for the second argument" do
        _("foo ? begin; bar; end : baz")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               s(:kwbegin, s(:send, nil, :bar)),
                               s(:send, nil, :baz))
      end

      it "keeps :kwbegin for the third argument" do
        _("foo ? bar : begin; baz; end")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar),
                               s(:kwbegin, s(:send, nil, :baz)))
      end
    end

    describe "for match operators" do
      it "handles :=~ with two non-literals" do
        _("foo =~ bar")
          .must_be_parsed_as s(:send,
                               s(:send, nil, :foo),
                               :=~,
                               s(:send, nil, :bar))
      end

      describe "with a regexp literal on the left hand side" do
        it "handles :=~ with a simple regexp literal" do
          _("/foo/ =~ bar")
            .must_be_parsed_as s(:match_with_lvasgn,
                                 s(:regexp, s(:str, "foo"), s(:regopt)),
                                 s(:send, nil, :bar))
        end

        it "handles :=~ with statically interpolated regexp" do
          _("/foo\#{'bar'}/ =~ baz")
            .must_be_parsed_as s(:match_with_lvasgn,
                                 s(:regexp,
                                   s(:str, "foo"),
                                   s(:begin,
                                     s(:str, "bar")),
                                   s(:regopt)),
                                 s(:send, nil, :baz))
        end

        it "handles :=~ with variable-assigning regexp" do
          _("/(?<foo>bar)/ =~ baz; foo")
            .must_be_parsed_as s(:begin,
                                 s(:match_with_lvasgn,
                                   s(:regexp,
                                     s(:str, "(?<foo>bar)"),
                                     s(:regopt)),
                                   s(:send, nil, :baz)),
                                 s(:lvar, :foo))
        end

        it "handles :=~ with statically interpolated variable-assigning regexp" do
          _("/(?<foo>\#{'bar'})/ =~ baz; foo")
            .must_be_parsed_as s(:begin,
                                 s(:match_with_lvasgn,
                                   s(:regexp,
                                     s(:str, "(?<foo>"),
                                     s(:begin,
                                       s(:str, "bar")),
                                     s(:str, ")"),
                                     s(:regopt)),
                                   s(:send, nil, :baz)),
                                 s(:lvar, :foo))
        end

        it "handles :=~ with interpolated regexp" do
          _("/\#{foo}/ =~ bar")
            .must_be_parsed_as s(:send,
                                 s(:regexp,
                                   s(:begin, s(:send, nil, :foo)),
                                   s(:regopt)), :=~,
                                 s(:send, nil, :bar))
        end

        it "handles :=~ with multi-part interpolated regexp" do
          _("/foo\#{bar}baz/ =~ qux")
            .must_be_parsed_as s(:send,
                                 s(:regexp,
                                   s(:str, "foo"),
                                   s(:begin,
                                     s(:send, nil, :bar)),
                                   s(:str, "baz"),
                                   s(:regopt)), :=~,
                                 s(:send, nil, :qux))
        end
      end

      it "handles :=~ with literal regexp on the right hand side" do
        _("foo =~ /bar/")
          .must_be_parsed_as s(:send,
                               s(:send, nil, :foo),
                               :=~,
                               s(:regexp, s(:str, "bar"), s(:regopt)))
      end

      it "handles negated match operators" do
        _("foo !~ bar").must_be_parsed_as s(:send,
                                            s(:send, nil, :foo),
                                            :!~,
                                            s(:send, nil, :bar))
      end
    end
  end
end
