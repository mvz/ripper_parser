# frozen_string_literal: true

require File.expand_path("../../test_helper.rb", File.dirname(__FILE__))

describe RipperParser::Parser do
  describe "#parse" do
    describe "for instance method definitions" do
      it "treats kwargs as a local variable" do
        _("def foo(**bar); bar; end")
          .must_be_parsed_as s(:def,
                               :foo,
                               s(:args, s(:kwrestarg, :bar)),
                               s(:lvar, :bar))
      end

      it "treats kwargs as a local variable when other arguments are present" do
        _("def foo(bar, **baz); baz; end")
          .must_be_parsed_as s(:def,
                               :foo,
                               s(:args, s(:arg, :bar), s(:kwrestarg, :baz)),
                               s(:lvar, :baz))
      end

      it "treats kwargs as a local variable when an explicit block is present" do
        _("def foo(**bar, &baz); bar; end")
          .must_be_parsed_as s(:def,
                               :foo,
                               s(:args, s(:kwrestarg, :bar), s(:blockarg, :baz)),
                               s(:lvar, :bar))
      end

      it "treats kwargs as a local variable in a block with kwargs" do
        _("def foo(**bar); baz { |**qux| bar; qux }; end")
          .must_be_parsed_as s(:def, :foo,
                               s(:args,
                                 s(:kwrestarg, :bar)),
                               s(:block,
                                 s(:send, nil, :baz),
                                 s(:args,
                                   s(:kwrestarg, :qux)),
                                 s(:begin,
                                   s(:lvar, :bar),
                                   s(:lvar, :qux))))
      end

      it "works with a method argument with a default value" do
        _("def foo bar=nil; end")
          .must_be_parsed_as s(:def,
                               :foo,
                               s(:args,
                                 s(:optarg, :bar, s(:nil))),
                               nil)
      end

      it "works with several method arguments with default values" do
        _("def foo bar=1, baz=2; end")
          .must_be_parsed_as s(:def,
                               :foo,
                               s(:args,
                                 s(:optarg, :bar, s(:int, 1)),
                                 s(:optarg, :baz, s(:int, 2))),
                               nil)
      end

      it "works with parentheses around the parameter list" do
        _("def foo(bar); end")
          .must_be_parsed_as s(:def, :foo, s(:args, s(:arg, :bar)), nil)
      end

      it "works with a simple splat" do
        _("def foo *bar; end")
          .must_be_parsed_as s(:def, :foo, s(:args, s(:restarg, :bar)), nil)
      end

      it "works with a regular argument plus splat" do
        _("def foo bar, *baz; end")
          .must_be_parsed_as s(:def, :foo,
                               s(:args, s(:arg, :bar), s(:restarg, :baz)), nil)
      end

      it "works with a nameless splat" do
        _("def foo *; end")
          .must_be_parsed_as s(:def,
                               :foo,
                               s(:args, s(:restarg)),
                               nil)
      end

      it "works with a nameless kwrest argument" do
        _("def foo **; end")
          .must_be_parsed_as s(:def,
                               :foo,
                               s(:args, s(:kwrestarg)),
                               nil)
      end

      it "works for a simple case with explicit block parameter" do
        _("def foo &bar; end")
          .must_be_parsed_as s(:def,
                               :foo,
                               s(:args, s(:blockarg, :bar)),
                               nil)
      end

      it "works with a regular argument plus explicit block parameter" do
        _("def foo bar, &baz; end")
          .must_be_parsed_as s(:def,
                               :foo,
                               s(:args, s(:arg, :bar), s(:blockarg, :baz)),
                               nil)
      end

      it "works with a default value plus explicit block parameter" do
        _("def foo bar=1, &baz; end")
          .must_be_parsed_as s(:def,
                               :foo,
                               s(:args,
                                 s(:optarg, :bar, s(:int, 1)),
                                 s(:blockarg, :baz)),
                               nil)
      end

      it "works with a default value plus mandatory argument" do
        _("def foo bar=1, baz; end")
          .must_be_parsed_as s(:def,
                               :foo,
                               s(:args,
                                 s(:optarg, :bar, s(:int, 1)),
                                 s(:arg, :baz)),
                               nil)
      end

      it "works with a splat plus explicit block parameter" do
        _("def foo *bar, &baz; end")
          .must_be_parsed_as s(:def,
                               :foo,
                               s(:args, s(:restarg, :bar), s(:blockarg, :baz)),
                               nil)
      end

      it "works for a bare block parameter" do
        if RUBY_VERSION < "3.1.0"
          skip "This Ruby version does not support bare block parameters"
        end
        _("def foo &; end")
          .must_be_parsed_as s(:def,
                               :foo,
                               s(:args, s(:blockarg, nil)),
                               nil)
      end

      it "works with a default value plus splat" do
        _("def foo bar=1, *baz; end")
          .must_be_parsed_as s(:def,
                               :foo,
                               s(:args,
                                 s(:optarg, :bar, s(:int, 1)),
                                 s(:restarg, :baz)),
                               nil)
      end

      it "works with a default value, splat, plus final mandatory arguments" do
        _("def foo bar=1, *baz, qux, quuz; end")
          .must_be_parsed_as s(:def,
                               :foo,
                               s(:args,
                                 s(:optarg, :bar, s(:int, 1)),
                                 s(:restarg, :baz),
                                 s(:arg, :qux),
                                 s(:arg, :quuz)),
                               nil)
      end

      it "works with a named argument with a default value" do
        _("def foo bar: 1; end")
          .must_be_parsed_as s(:def,
                               :foo,
                               s(:args,
                                 s(:kwoptarg, :bar, s(:int, 1))),
                               nil)
      end

      it "works with a named argument with no default value" do
        _("def foo bar:; end")
          .must_be_parsed_as s(:def,
                               :foo,
                               s(:args,
                                 s(:kwarg, :bar)),
                               nil)
      end

      it "works with a double splat" do
        _("def foo **bar; end")
          .must_be_parsed_as s(:def,
                               :foo,
                               s(:args, s(:kwrestarg, :bar)),
                               nil)
      end

      it "works with argument destructuring" do
        _("def foo((bar, baz)); end")
          .must_be_parsed_as s(:def, :foo,
                               s(:args,
                                 s(:mlhs,
                                   s(:arg, :bar),
                                   s(:arg, :baz))),
                               nil)
      end

      it "works with argument destructuring including splat" do
        _("def foo((bar, *baz)); end")
          .must_be_parsed_as s(:def, :foo,
                               s(:args,
                                 s(:mlhs,
                                   s(:arg, :bar),
                                   s(:restarg, :baz))),
                               nil)
      end

      it "works with nested argument destructuring" do
        _("def foo((bar, (baz, qux))); end")
          .must_be_parsed_as s(:def, :foo,
                               s(:args,
                                 s(:mlhs,
                                   s(:arg, :bar),
                                   s(:mlhs,
                                     s(:arg, :baz),
                                     s(:arg, :qux)))), nil)
      end

      it "works when the method name is an operator" do
        _("def +; end")
          .must_be_parsed_as s(:def, :+, s(:args),
                               nil)
      end

      it "works when the method name is a keyword" do
        _("def for; end")
          .must_be_parsed_as s(:def, :for, s(:args),
                               nil)
      end

      it "works with argument forwarding" do
        _("def foo(...); bar(...); end")
          .must_be_parsed_as s(:def, :foo,
                               s(:args, s(:forward_arg)),
                               s(:send, nil, :bar,
                                 s(:forwarded_args)))
      end

      it "works with argument forwarding with leading call arguments" do
        # Implemented in 3.0 and backported to 2.7.3.
        # See https://bugs.ruby-lang.org/issues/16378
        if RUBY_VERSION < "2.7.3"
          skip "This Ruby version does not support this style of argument forwarding"
        end
        _("def foo(...); bar(baz, ...); end")
          .must_be_parsed_as s(:def, :foo,
                               s(:args, s(:forward_arg)),
                               s(:send, nil, :bar,
                                 s(:send, nil, :baz), s(:forwarded_args)))
      end

      it "works with argument forwarding with leading method arguments" do
        # Implemented in 3.0 and backported to 2.7.3.
        # See https://bugs.ruby-lang.org/issues/16378
        if RUBY_VERSION < "2.7.3"
          skip "This Ruby version does not support this style of argument forwarding"
        end
        _("def foo(bar, ...); baz(...); end")
          .must_be_parsed_as s(:def, :foo,
                               s(:args, s(:arg, :bar), s(:forward_arg)),
                               s(:send, nil, :baz,
                                 s(:forwarded_args)))
      end

      it "works for multi-statement method body with argument forwarding" \
         " with leading method arguments" do
        # Implemented in 3.0 and backported to 2.7.3.
        # See https://bugs.ruby-lang.org/issues/16378
        if RUBY_VERSION < "2.7.3"
          skip "This Ruby version does not support this style of argument forwarding"
        end
        _("def foo(bar, ...); baz bar; qux(...); end")
          .must_be_parsed_as s(:def, :foo,
                               s(:args, s(:arg, :bar), s(:forward_arg)),
                               s(:begin,
                                 s(:send, nil, :baz, s(:lvar, :bar)),
                                 s(:send, nil, :qux, s(:forwarded_args))))
      end

      it "works with an anonymous double splat argument" do
        _("def foo(**); end")
          .must_be_parsed_as s(:def, :foo,
                               s(:args, s(:kwrestarg)),
                               nil)
      end

      it "assigns correct line numbers when the body is empty" do
        _("def bar\nend")
          .must_be_parsed_as s(:def, :bar,
                               s(:args).line(1), nil).line(1),
                             with_line_numbers: true
      end

      it "handles a method named 'class'" do
        _("def class; end")
          .must_be_parsed_as s(:def, :class, s(:args), nil)
      end
    end

    describe "for endless instance method definitions" do
      before do
        skip "This Ruby version does not support endless methods" if RUBY_VERSION < "3.0.0"
      end

      it "works for a method with simple arguments" do
        _("def foo(bar) = baz(bar)")
          .must_be_parsed_as s(:def, :foo,
                               s(:args, s(:arg, :bar)),
                               s(:send, nil, :baz, s(:lvar, :bar)))
      end

      it "works for a method with rescue" do
        _("def foo(bar) = baz(bar) rescue qux")
          .must_be_parsed_as s(:def, :foo,
                               s(:args, s(:arg, :bar)),
                               s(:rescue,
                                 s(:send, nil, :baz, s(:lvar, :bar)),
                                 s(:resbody, nil, nil,
                                   s(:send, nil, :qux)), nil))
      end

      it "works for a method without arguments" do
        _("def foo = bar")
          .must_be_parsed_as s(:def, :foo, s(:args), s(:send, nil, :bar))
      end

      it "works when the body calls a method without parentheses" do
        skip "This Ruby version does not support this syntax" if RUBY_VERSION < "3.1.0"
        _("def foo = bar 42")
          .must_be_parsed_as s(:def, :foo, s(:args), s(:send, nil, :bar, s(:int, 42)))
      end
    end

    describe "for singleton method definitions" do
      it "works with empty body" do
        _("def foo.bar; end")
          .must_be_parsed_as s(:defs,
                               s(:send, nil, :foo),
                               :bar,
                               s(:args),
                               nil)
      end

      it "works with a body with multiple statements" do
        _("def foo.bar; baz; qux; end")
          .must_be_parsed_as s(:defs,
                               s(:send, nil, :foo),
                               :bar,
                               s(:args),
                               s(:begin,
                                 s(:send, nil, :baz),
                                 s(:send, nil, :qux)))
      end

      it "works with a simple splat" do
        _("def foo.bar *baz; end")
          .must_be_parsed_as s(:defs,
                               s(:send, nil, :foo),
                               :bar,
                               s(:args, s(:restarg, :baz)),
                               nil)
      end

      it "works when the method name is a keyword" do
        _("def foo.for; end")
          .must_be_parsed_as s(:defs,
                               s(:send, nil, :foo),
                               :for, s(:args),
                               nil)
      end
    end

    describe "for endless singleton method definitions" do
      before do
        skip "This Ruby version does not support endless methods" if RUBY_VERSION < "3.0.0"
      end

      it "works for a method with simple arguments" do
        _("def self.foo(bar) = baz(bar)")
          .must_be_parsed_as s(:defs,
                               s(:self),
                               :foo,
                               s(:args, s(:arg, :bar)),
                               s(:send, nil, :baz, s(:lvar, :bar)))
      end

      it "works for a method with rescue" do
        _("def self.foo(bar) = baz(bar) rescue qux")
          .must_be_parsed_as s(:defs,
                               s(:self),
                               :foo,
                               s(:args, s(:arg, :bar)),
                               s(:rescue,
                                 s(:send, nil, :baz, s(:lvar, :bar)),
                                 s(:resbody, nil, nil, s(:send, nil, :qux)), nil))
      end

      it "works for a method without arguments" do
        _("def self.foo = bar")
          .must_be_parsed_as s(:defs, s(:self), :foo, s(:args), s(:send, nil, :bar))
      end
    end

    describe "for the alias statement" do
      it "works with regular barewords" do
        _("alias foo bar")
          .must_be_parsed_as s(:alias,
                               s(:sym, :foo), s(:sym, :bar))
      end

      it "works with symbols" do
        _("alias :foo :bar")
          .must_be_parsed_as s(:alias,
                               s(:sym, :foo), s(:sym, :bar))
      end

      it "works with operator barewords" do
        _("alias + -")
          .must_be_parsed_as s(:alias,
                               s(:sym, :+), s(:sym, :-))
      end

      it "treats keywords as symbols" do
        _("alias next foo")
          .must_be_parsed_as s(:alias, s(:sym, :next), s(:sym, :foo))
      end

      it "works with global variables" do
        _("alias $foo $bar")
          .must_be_parsed_as s(:valias, :$foo, :$bar)
      end
    end

    describe "for the undef statement" do
      it "works with a single bareword identifier" do
        _("undef foo")
          .must_be_parsed_as s(:undef, s(:sym, :foo))
      end

      it "works with a single symbol" do
        _("undef :foo")
          .must_be_parsed_as s(:undef, s(:sym, :foo))
      end

      it "works with multiple bareword identifiers" do
        _("undef foo, bar")
          .must_be_parsed_as s(:undef,
                               s(:sym, :foo),
                               s(:sym, :bar))
      end

      it "works with multiple bareword symbols" do
        _("undef :foo, :bar")
          .must_be_parsed_as s(:undef,
                               s(:sym, :foo),
                               s(:sym, :bar))
      end
    end

    describe "for the return statement" do
      it "works with no arguments" do
        _("return")
          .must_be_parsed_as s(:return)
      end

      it "works with one argument" do
        _("return foo")
          .must_be_parsed_as s(:return,
                               s(:send, nil, :foo))
      end

      it "works with a splat argument" do
        _("return *foo")
          .must_be_parsed_as s(:return,
                               s(:splat,
                                 s(:send, nil, :foo)))
      end

      it "works with multiple arguments" do
        _("return foo, bar")
          .must_be_parsed_as s(:return,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar))
      end

      it "works with a regular argument and a splat argument" do
        _("return foo, *bar")
          .must_be_parsed_as s(:return,
                               s(:send, nil, :foo),
                               s(:splat,
                                 s(:send, nil, :bar)))
      end

      it "works with a function call with parentheses" do
        _("return foo(bar)")
          .must_be_parsed_as s(:return,
                               s(:send, nil, :foo,
                                 s(:send, nil, :bar)))
      end

      it "works with a function call without parentheses" do
        _("return foo bar")
          .must_be_parsed_as s(:return,
                               s(:send, nil, :foo,
                                 s(:send, nil, :bar)))
      end
    end

    describe "for yield" do
      it "works with no arguments and no parentheses" do
        _("yield")
          .must_be_parsed_as s(:yield)
      end

      it "works with parentheses but no arguments" do
        _("yield()")
          .must_be_parsed_as s(:yield)
      end

      it "works with one argument and no parentheses" do
        _("yield foo")
          .must_be_parsed_as s(:yield, s(:send, nil, :foo))
      end

      it "works with one argument and parentheses" do
        _("yield(foo)")
          .must_be_parsed_as s(:yield, s(:send, nil, :foo))
      end

      it "works with multiple arguments and no parentheses" do
        _("yield foo, bar")
          .must_be_parsed_as s(:yield,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar))
      end

      it "works with multiple arguments and parentheses" do
        _("yield(foo, bar)")
          .must_be_parsed_as s(:yield,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar))
      end

      it "works with splat" do
        _("yield foo, *bar")
          .must_be_parsed_as s(:yield,
                               s(:send, nil, :foo),
                               s(:splat, s(:send, nil, :bar)))
      end

      it "works with a function call with parentheses" do
        _("yield foo(bar)")
          .must_be_parsed_as s(:yield,
                               s(:send, nil, :foo,
                                 s(:send, nil, :bar)))
      end

      it "works with a function call without parentheses" do
        _("yield foo bar")
          .must_be_parsed_as s(:yield,
                               s(:send, nil, :foo,
                                 s(:send, nil, :bar)))
      end
    end
  end
end
