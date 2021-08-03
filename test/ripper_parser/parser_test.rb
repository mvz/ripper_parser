# frozen_string_literal: true

require File.expand_path("../test_helper.rb", File.dirname(__FILE__))

describe RipperParser::Parser do
  let(:parser) { RipperParser::Parser.new }
  describe "#parse" do
    it "returns an s-expression" do
      result = parser.parse "foo"
      _(result).must_be_instance_of Sexp
    end

    describe "for an empty program" do
      it "returns nil" do
        _("").must_be_parsed_as nil
      end
    end

    describe "for a class declaration" do
      it "works with a namespaced class name" do
        _("class Foo::Bar; end")
          .must_be_parsed_as s(:class,
                               s(:const, s(:const, nil, :Foo), :Bar),
                               nil, nil)
      end

      it "works for singleton classes" do
        _("class << self; end").must_be_parsed_as s(:sclass, s(:self), nil)
      end
    end

    describe "for a module declaration" do
      it "works with a simple module name" do
        _("module Foo; end")
          .must_be_parsed_as s(:module, s(:const, nil, :Foo), nil)
      end

      it "works with a namespaced module name" do
        _("module Foo::Bar; end")
          .must_be_parsed_as s(:module,
                               s(:const, s(:const, nil, :Foo), :Bar), nil)
      end
    end

    describe "for empty parentheses" do
      it "works with lone ()" do
        _("()").must_be_parsed_as s(:nil)
      end
    end

    describe "for a begin..end block" do
      it "works with no statements" do
        _("begin; end")
          .must_be_parsed_as s(:kwbegin)
      end

      it "works with one statement" do
        _("begin; foo; end")
          .must_be_parsed_as s(:kwbegin, s(:send, nil, :foo))
      end

      it "works with multiple statements" do
        _("begin; foo; bar; end")
          .must_be_parsed_as s(:kwbegin,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar))
      end
    end

    describe "for arguments" do
      it "works for a simple case with splat" do
        _("foo *bar")
          .must_be_parsed_as s(:send,
                               nil,
                               :foo,
                               s(:splat, s(:send, nil, :bar)))
      end

      it "works for a multi-argument case with splat" do
        _("foo bar, *baz")
          .must_be_parsed_as s(:send,
                               nil,
                               :foo,
                               s(:send, nil, :bar),
                               s(:splat, s(:send, nil, :baz)))
      end

      it "works for a simple case passing a block" do
        _("foo &bar")
          .must_be_parsed_as s(:send, nil, :foo,
                               s(:block_pass,
                                 s(:send, nil, :bar)))
      end

      it "works for keyword arguments" do
        _("foo bar => baz")
          .must_be_parsed_as s(:send, nil, :foo,
                               s(:kwargs,
                                 s(:pair,
                                   s(:send, nil, :bar),
                                   s(:send, nil, :baz))))
      end
    end

    describe "for the __ENCODING__ keyword" do
      it "evaluates to the equivalent of Encoding::UTF_8" do
        _("__ENCODING__")
          .must_be_parsed_as s(:__ENCODING__)
      end
    end

    describe "for the __FILE__ keyword" do
      describe "when not passing a file name" do
        it "creates a string sexp with value '(string)'" do
          _("__FILE__")
            .must_be_parsed_as s(:str, "(string)")
        end
      end

      describe "when passing a file name" do
        it "creates a string sexp with the file name" do
          result = parser.parse "__FILE__", "foo"
          _(result).must_equal s(:str, "foo")
        end
      end
    end

    describe "for the __LINE__ keyword" do
      it "creates a literal sexp with value of the line number" do
        _("__LINE__")
          .must_be_parsed_as s(:int, 1)
        _("\n__LINE__")
          .must_be_parsed_as s(:int, 2)
      end
    end

    describe "for the END keyword" do
      it "converts to a :postexe iterator" do
        _("END { foo }")
          .must_be_parsed_as s(:postexe, s(:send, nil, :foo))
      end

      it "works with an empty block" do
        _("END { }")
          .must_be_parsed_as s(:postexe, nil)
      end

      it "assigns correct line numbers" do
        _("END {\nfoo\n}")
          .must_be_parsed_as s(:postexe,
                               s(:send, nil, :foo).line(2)).line(1),
                             with_line_numbers: true
      end

      it "assigns correct line numbers to a embedded begin block" do
        _("END {\nbegin\nfoo\nend\n}")
          .must_be_parsed_as s(:postexe,
                               s(:kwbegin,
                                 s(:send, nil, :foo).line(3)).line(2)).line(1),
                             with_line_numbers: true
      end
    end

    describe "for the BEGIN keyword" do
      it "converts to a :preexe iterator" do
        _("BEGIN { foo }")
          .must_be_parsed_as s(:preexe, s(:send, nil, :foo))
      end

      it "works with an empty block" do
        _("BEGIN { }")
          .must_be_parsed_as s(:preexe, nil)
      end

      it "assigns correct line numbers" do
        _("BEGIN {\nfoo\n}")
          .must_be_parsed_as s(:preexe,
                               s(:send, nil, :foo).line(2)).line(1),
                             with_line_numbers: true
      end

      it "assigns correct line numbers to a embedded begin block" do
        _("BEGIN {\nbegin\nfoo\nend\n}")
          .must_be_parsed_as s(:preexe,
                               s(:kwbegin,
                                 s(:send, nil, :foo).line(3)).line(2)).line(1),
                             with_line_numbers: true
      end
    end

    describe "for the defined? keyword" do
      it "converts to a sexp of type :defined?" do
        _("defined? foo")
          .must_be_parsed_as s(:defined?, s(:send, nil, :foo))
      end
    end

    describe "for constant lookups" do
      it "works when explicitely starting from the root namespace" do
        _("::Foo")
          .must_be_parsed_as s(:const, s(:cbase), :Foo)
      end

      it "works with a three-level constant lookup" do
        _("Foo::Bar::Baz")
          .must_be_parsed_as s(:const,
                               s(:const, s(:const, nil, :Foo), :Bar),
                               :Baz)
      end

      it "works looking up a constant in a non-constant" do
        _("foo::Bar").must_be_parsed_as s(:const,
                                          s(:send, nil, :foo),
                                          :Bar)
      end
    end

    describe "for variable references" do
      it "works for self" do
        _("self")
          .must_be_parsed_as s(:self)
      end

      it "works for instance variables" do
        _("@foo")
          .must_be_parsed_as s(:ivar, :@foo)
      end

      it "works for global variables" do
        _("$foo")
          .must_be_parsed_as s(:gvar, :$foo)
      end

      it "works for regexp match references" do
        _("$1")
          .must_be_parsed_as s(:nth_ref, 1)
      end

      specify { _("$'").must_be_parsed_as s(:back_ref, :"'") }
      specify { _("$&").must_be_parsed_as s(:back_ref, :&) }

      it "works for class variables" do
        _("@@foo")
          .must_be_parsed_as s(:cvar, :@@foo)
      end
    end

    describe "for expressions" do
      it "handles assignment inside binary operator expressions" do
        _("foo + (bar = baz)")
          .must_be_parsed_as s(:send,
                               s(:send, nil, :foo), :+,
                               s(:begin,
                                 s(:lvasgn, :bar,
                                   s(:send, nil, :baz))))
      end

      it "handles assignment inside unary operator expressions" do
        _("+(foo = bar)")
          .must_be_parsed_as s(:send,
                               s(:begin,
                                 s(:lvasgn, :foo, s(:send, nil, :bar))),
                               :+@)
      end
    end

    # NOTE: differences in the handling of comments are not caught by Sexp's
    # implementation of equality.
    describe "for comments" do
      it "handles method comments" do
        result = parser.parse "# Foo\ndef foo; end"
        _(result).must_equal s(:def,
                               :foo,
                               s(:args), nil)
        _(result.comments).must_equal "# Foo\n"
      end

      it "handles comments for methods with explicit receiver" do
        result = parser.parse "# Foo\ndef foo.bar; end"
        _(result).must_equal s(:defs,
                               s(:send, nil, :foo),
                               :bar,
                               s(:args),
                               nil)
        _(result.comments).must_equal "# Foo\n"
      end

      it "matches comments to the correct entity" do
        result = parser.parse "# Foo\nclass Foo\n# Bar\ndef bar\nend\nend"
        _(result).must_equal s(:class, s(:const, nil, :Foo), nil,
                               s(:def, :bar,
                                 s(:args), nil))
        _(result.comments).must_equal "# Foo\n"
        defn = result[3]
        _(defn.sexp_type).must_equal :def
        _(defn.comments).must_equal "# Bar\n"
      end

      it "combines multi-line comments" do
        result = parser.parse "# Foo\n# Bar\ndef foo; end"
        _(result).must_equal s(:def,
                               :foo,
                               s(:args), nil)
        _(result.comments).must_equal "# Foo\n# Bar\n"
      end

      it "drops comments inside method bodies" do
        result = parser.parse <<-RUBY
          # Foo
          class Foo
            # foo
            def foo
              bar # this is dropped
            end

            # bar
            def bar
              baz
            end
          end
        RUBY
        _(result).must_equal s(:class,
                               s(:const, nil, :Foo),
                               nil,
                               s(:begin,
                                 s(:def, :foo, s(:args), s(:send, nil, :bar)),
                                 s(:def, :bar, s(:args), s(:send, nil, :baz))))
        _(result.comments).must_equal "# Foo\n"
        _(result[3][1].comments).must_equal "# foo\n"
        _(result[3][2].comments).must_equal "# bar\n"
      end

      it "handles the use of symbols that are keywords" do
        result = parser.parse "# Foo\ndef bar\n:class\nend"
        _(result).must_equal s(:def,
                               :bar,
                               s(:args),
                               s(:sym, :class))
        _(result.comments).must_equal "# Foo\n"
      end

      it "handles use of singleton class inside methods" do
        result = parser.parse "# Foo\ndef bar\nclass << self\nbaz\nend\nend"
        _(result).must_equal s(:def,
                               :bar,
                               s(:args),
                               s(:sclass, s(:self),
                                 s(:send, nil, :baz)))
        _(result.comments).must_equal "# Foo\n"
      end

      it "assigns comments on BEGIN blocks to the BEGIN block" do
        result = parser.parse "# Bar\nBEGIN { }\n# Foo\ndef foo; end"
        _(result).must_equal s(:begin,
                               s(:preexe, nil),
                               s(:def, :foo, s(:args), nil))
        _(result[1].comments).must_equal "# Bar\n"
        _(result[2].comments).must_equal "# Foo\n"
      end

      it "assigns comments on multiple BEGIN blocks to each block" do
        result = parser.parse "# Bar\nBEGIN { }\n# Baz\nBEGIN { }\n# Foo\ndef foo; end"
        _(result).must_equal s(:begin,
                               s(:preexe, nil),
                               s(:preexe, nil),
                               s(:def, :foo, s(:args), nil))
        _(result[1].comments).must_equal "# Bar\n"
        _(result[2].comments).must_equal "# Baz\n"
        _(result[3].comments).must_equal "# Foo\n"
      end

      it "assigns comments on BEGIN blocks to the first following item" do
        result = parser.parse "# Bar\nBEGIN { }\n# Foo\nclass Bar\n# foo\ndef foo; end\nend"
        _(result).must_equal s(:begin,
                               s(:preexe, nil),
                               s(:class, s(:const, nil, :Bar), nil,
                                 s(:def, :foo, s(:args), nil)))
        _(result[1].comments).must_equal "# Bar\n"
        _(result[2].comments).must_equal "# Foo\n"
        _(result[2][3].comments).must_equal "# foo\n"
      end
    end

    # NOTE: differences in the handling of line numbers are not caught by
    # Sexp's implementation of equality.
    describe "assigning line numbers" do
      it "works for a plain method call" do
        result = parser.parse "foo"
        _(result.line).must_equal 1
      end

      it "works for a method call with parentheses" do
        result = parser.parse "foo()"
        _(result.line).must_equal 1
      end

      it "works for a method call with receiver" do
        result = parser.parse "foo.bar"
        _(result.line).must_equal 1
      end

      it "works for a method call with receiver and arguments" do
        result = parser.parse "foo.bar baz"
        _(result.line).must_equal 1
      end

      it "works for a method call with arguments" do
        result = parser.parse "foo bar"
        _(result.line).must_equal 1
      end

      it "works for a block with two lines" do
        result = parser.parse "foo\nbar\n"
        _(result.sexp_type).must_equal :begin
        _(result[1].line).must_equal 1
        _(result[2].line).must_equal 2
        _(result.line).must_equal 1
      end

      it "works for a constant reference" do
        result = parser.parse "Foo"
        _(result.line).must_equal 1
      end

      it "works for an instance variable" do
        result = parser.parse "@foo"
        _(result.line).must_equal 1
      end

      it "works for a global variable" do
        result = parser.parse "$foo"
        _(result.line).must_equal 1
      end

      it "works for a class variable" do
        result = parser.parse "@@foo"
        _(result.line).must_equal 1
      end

      it "works for a local variable" do
        _("foo = bar\nfoo\n")
          .must_be_parsed_as s(:begin,
                               s(:lvasgn, :foo, s(:send, nil, :bar).line(1)).line(1),
                               s(:lvar, :foo).line(2)).line(1),
                             with_line_numbers: true
      end

      it "works for an integer literal" do
        result = parser.parse "42"
        _(result.line).must_equal 1
      end

      it "works for a float literal" do
        result = parser.parse "3.14"
        _(result.line).must_equal 1
      end

      it "works for a range literal" do
        result = parser.parse "0..4"
        _(result.line).must_equal 1
      end

      it "works for an exclusive range literal" do
        result = parser.parse "0...4"
        _(result.line).must_equal 1
      end

      it "works for a symbol literal" do
        result = parser.parse ":foo"
        _(result.line).must_equal 1
      end

      it "works for a keyword-like symbol literal" do
        result = parser.parse ":and"
        _(result.line).must_equal 1
      end

      it "works for a string literal" do
        result = parser.parse '"foo"'
        _(result.line).must_equal 1
      end

      it "works for a backtick string literal" do
        result = parser.parse "`foo`"
        _(result.line).must_equal 1
      end

      it "works for a plain regexp literal" do
        result = parser.parse "/foo/"
        _(result.line).must_equal 1
      end

      it "works for a regular expression back reference" do
        result = parser.parse "$1"
        _(result.line).must_equal 1
      end

      it "works for self" do
        result = parser.parse "self"
        _(result.line).must_equal 1
      end

      it "works for __FILE__" do
        result = parser.parse "__FILE__"
        _(result.line).must_equal 1
      end

      it "works for nil" do
        result = parser.parse "nil"
        _(result.line).must_equal 1
      end

      it "works for a symbol literal" do
        result = parser.parse ":foo"
        _(result.line).must_equal 1
      end

      it "works for a class definition" do
        result = parser.parse "class Foo; end"
        _(result.line).must_equal 1
      end

      it "works for a module definition" do
        result = parser.parse "module Foo; end"
        _(result.line).must_equal 1
      end

      it "works for a method definition" do
        result = parser.parse "def foo; end"
        _(result.line).must_equal 1
      end

      it "works for assignment of the empty hash" do
        result = parser.parse "foo = {}"
        _(result.line).must_equal 1
      end

      it "works for multiple assignment of empty hashes" do
        result = parser.parse "foo, bar = {}, {}"
        _(result.line).must_equal 1
      end

      it "assigns line numbers to nested sexps without their own line numbers" do
        _("foo(bar) do\nnext baz\nend\n")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo, s(:send, nil, :bar).line(1)).line(1),
                               s(:args),
                               s(:next, s(:send, nil, :baz).line(2)).line(2)).line(1),
                             with_line_numbers: true
      end

      describe "when a line number is passed" do
        it "shifts all line numbers as appropriate" do
          result = parser.parse "foo\nbar\n", "(string)", 3
          _(result).must_equal s(:begin,
                                 s(:send, nil, :foo),
                                 s(:send, nil, :bar))
          _(result.line).must_equal 3
          _(result[1].line).must_equal 3
          _(result[2].line).must_equal 4
        end
      end
    end
  end

  describe "#trickle_up_line_numbers" do
    it "works through several nested levels" do
      inner = s(:foo)
      outer = s(:bar, s(:baz, s(:qux, inner)))
      outer.line = 42
      parser.send :trickle_down_line_numbers, outer
      _(inner.line).must_equal 42
    end
  end

  describe "#trickle_down_line_numbers" do
    it "works through several nested levels" do
      inner = s(:foo)
      inner.line = 42
      outer = s(:bar, s(:baz, s(:qux, inner)))
      parser.send :trickle_up_line_numbers, outer
      _(outer.line).must_equal 42
    end
  end
end
