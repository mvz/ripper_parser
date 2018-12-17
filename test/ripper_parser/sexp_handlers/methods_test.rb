require File.expand_path('../../test_helper.rb', File.dirname(__FILE__))

describe RipperParser::Parser do
  describe '#parse' do
    describe 'for instance method definitions' do
      it 'treats kwargs as a local variable' do
        'def foo(**bar); bar; end'.
          must_be_parsed_as s(:def,
                              :foo,
                              s(:args, s(:kwrestarg, :bar)),
                              s(:lvar, :bar))
      end

      it 'treats kwargs as a local variable when other arguments are present' do
        'def foo(bar, **baz); baz; end'.
          must_be_parsed_as s(:def,
                              :foo,
                              s(:args, s(:arg, :bar), s(:kwrestarg, :baz)),
                              s(:lvar, :baz))
      end

      it 'treats kwargs as a local variable when an explicit block is present' do
        'def foo(**bar, &baz); bar; end'.
          must_be_parsed_as s(:def,
                              :foo,
                              s(:args, s(:kwrestarg, :bar), s(:blockarg, :baz)),
                              s(:lvar, :bar))
      end

      it 'works with a method argument with a default value' do
        'def foo bar=nil; end'.
          must_be_parsed_as s(:def,
                              :foo,
                              s(:args, s(:lvasgn, :bar, s(:nil))),
                              nil)
      end

      it 'works with several method arguments with default values' do
        'def foo bar=1, baz=2; end'.
          must_be_parsed_as s(:def,
                              :foo,
                              s(:args,
                                s(:lvasgn, :bar, s(:int, 1)),
                                s(:lvasgn, :baz, s(:int, 2))),
                              nil)
      end

      it 'works with parentheses around the parameter list' do
        'def foo(bar); end'.
          must_be_parsed_as s(:def, :foo, s(:args, s(:arg, :bar)), nil)
      end

      it 'works with a simple splat' do
        'def foo *bar; end'.
          must_be_parsed_as s(:def, :foo, s(:args, s(:restarg, :bar)), nil)
      end

      it 'works with a regular argument plus splat' do
        'def foo bar, *baz; end'.
          must_be_parsed_as s(:def, :foo,
                              s(:args, s(:arg, :bar), s(:restarg, :baz)), nil)
      end

      it 'works with a nameless splat' do
        'def foo *; end'.
          must_be_parsed_as s(:def,
                              :foo,
                              s(:args, s(:restarg)),
                              nil)
      end

      it 'works for a simple case with explicit block parameter' do
        'def foo &bar; end'.
          must_be_parsed_as s(:def,
                              :foo,
                              s(:args, s(:blockarg, :bar)),
                              nil)
      end

      it 'works with a regular argument plus explicit block parameter' do
        'def foo bar, &baz; end'.
          must_be_parsed_as s(:def,
                              :foo,
                              s(:args, s(:arg, :bar), s(:blockarg, :baz)),
                              nil)
      end

      it 'works with a default value plus explicit block parameter' do
        'def foo bar=1, &baz; end'.
          must_be_parsed_as s(:def,
                              :foo,
                              s(:args,
                                s(:lvasgn, :bar, s(:int, 1)),
                                s(:blockarg, :baz)),
                              nil)
      end

      it 'works with a default value plus mandatory argument' do
        'def foo bar=1, baz; end'.
          must_be_parsed_as s(:def,
                              :foo,
                              s(:args,
                                s(:lvasgn, :bar, s(:int, 1)),
                                s(:arg, :baz)),
                              nil)
      end

      it 'works with a splat plus explicit block parameter' do
        'def foo *bar, &baz; end'.
          must_be_parsed_as s(:def,
                              :foo,
                              s(:args, s(:restarg, :bar), s(:blockarg, :baz)),
                              nil)
      end

      it 'works with a default value plus splat' do
        'def foo bar=1, *baz; end'.
          must_be_parsed_as s(:def,
                              :foo,
                              s(:args,
                                s(:lvasgn, :bar, s(:int, 1)),
                                s(:restarg, :baz)),
                              nil)
      end

      it 'works with a default value, splat, plus final mandatory arguments' do
        'def foo bar=1, *baz, qux, quuz; end'.
          must_be_parsed_as s(:def,
                              :foo,
                              s(:args,
                                s(:lvasgn, :bar, s(:int, 1)),
                                s(:restarg, :baz),
                                s(:arg, :qux),
                                s(:arg, :quuz)),
                              nil)
      end

      it 'works with a named argument with a default value' do
        'def foo bar: 1; end'.
          must_be_parsed_as s(:def,
                              :foo,
                              s(:args,
                                s(:kwarg, :bar, s(:int, 1))),
                              nil)
      end

      it 'works with a named argument with no default value' do
        'def foo bar:; end'.
          must_be_parsed_as s(:def,
                              :foo,
                              s(:args,
                                s(:kwarg, :bar)),
                              nil)
      end

      it 'works with a double splat' do
        'def foo **bar; end'.
          must_be_parsed_as s(:def,
                              :foo,
                              s(:args, s(:kwrestarg, :bar)),
                              nil)
      end

      it 'works when the method name is an operator' do
        'def +; end'.
          must_be_parsed_as s(:def, :+, s(:args),
                              nil)
      end
    end

    describe 'for singleton method definitions' do
      it 'works with empty body' do
        'def foo.bar; end'.
          must_be_parsed_as s(:defs,
                              s(:send, nil, :foo),
                              :bar,
                              s(:args),
                              nil)
      end

      it 'works with a body with multiple statements' do
        'def foo.bar; baz; qux; end'.
          must_be_parsed_as s(:defs,
                              s(:send, nil, :foo),
                              :bar,
                              s(:args),
                              s(:send, nil, :baz),
                              s(:send, nil, :qux))
      end
    end

    describe 'for the alias statement' do
      it 'works with regular barewords' do
        'alias foo bar'.
          must_be_parsed_as s(:alias,
                              s(:sym, :foo), s(:sym, :bar))
      end

      it 'works with symbols' do
        'alias :foo :bar'.
          must_be_parsed_as s(:alias,
                              s(:sym, :foo), s(:sym, :bar))
      end

      it 'works with operator barewords' do
        'alias + -'.
          must_be_parsed_as s(:alias,
                              s(:sym, :+), s(:sym, :-))
      end

      it 'treats keywords as symbols' do
        'alias next foo'.
          must_be_parsed_as s(:alias, s(:sym, :next), s(:sym, :foo))
      end

      it 'works with global variables' do
        'alias $foo $bar'.
          must_be_parsed_as s(:valias, :$foo, :$bar)
      end
    end

    describe 'for the undef statement' do
      it 'works with a single bareword identifier' do
        'undef foo'.
          must_be_parsed_as s(:undef, s(:sym, :foo))
      end

      it 'works with a single symbol' do
        'undef :foo'.
          must_be_parsed_as s(:undef, s(:sym, :foo))
      end

      it 'works with multiple bareword identifiers' do
        'undef foo, bar'.
          must_be_parsed_as s(:undef,
                              s(:sym, :foo),
                              s(:sym, :bar))
      end

      it 'works with multiple bareword symbols' do
        'undef :foo, :bar'.
          must_be_parsed_as s(:undef,
                              s(:sym, :foo),
                              s(:sym, :bar))
      end
    end
  end
end
