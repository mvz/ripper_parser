require File.expand_path('../../test_helper.rb', File.dirname(__FILE__))

describe RipperParser::Parser do
  describe '#parse' do
    describe 'for single assignment' do
      it 'works when assigning to a namespaced constant' do
        'Foo::Bar = baz'.
          must_be_parsed_as s(:casgn,
                              s(:const, s(:const, nil, :Foo), :Bar),
                              s(:send, nil, :baz))
      end

      it 'works when assigning to constant in the root namespace' do
        '::Foo = bar'.
          must_be_parsed_as s(:casgn,
                              s(:cbase, :Foo),
                              s(:send, nil, :bar))
      end

      it 'works with blocks' do
        'foo = begin; bar; end'.
          must_be_parsed_as s(:lvasgn, :foo, s(:kwbegin, s(:send, nil, :bar)))
      end

      describe 'with a right-hand splat' do
        it 'works in the simple case' do
          'foo = *bar'.
            must_be_parsed_as s(:lvasgn, :foo,
                                s(:svalue,
                                  s(:splat,
                                    s(:send, nil, :bar))))
        end

        it 'works with blocks' do
          'foo = *begin; bar; end'.
            must_be_parsed_as s(:lvasgn, :foo,
                                s(:svalue,
                                  s(:splat,
                                    s(:kwbegin,
                                      s(:send, nil, :bar)))))
        end
      end

      describe 'with several items on the right hand side' do
        it 'works in the simple case' do
          'foo = bar, baz'.
            must_be_parsed_as s(:lvasgn, :foo,
                                s(:svalue,
                                  s(:array,
                                    s(:send, nil, :bar),
                                    s(:send, nil, :baz))))
        end

        it 'works with a splat' do
          'foo = bar, *baz'.
            must_be_parsed_as s(:lvasgn, :foo,
                                s(:svalue,
                                  s(:array,
                                    s(:send, nil, :bar),
                                    s(:splat,
                                      s(:send, nil, :baz)))))
        end
      end

      describe 'with an array literal on the right hand side' do
        specify do
          'foo = [bar, baz]'.
            must_be_parsed_as s(:lvasgn, :foo,
                                s(:array,
                                  s(:send, nil, :bar),
                                  s(:send, nil, :baz)))
        end
      end

      it 'works when assigning to an instance variable' do
        '@foo = bar'.
          must_be_parsed_as s(:ivasgn,
                              :@foo,
                              s(:send, nil, :bar))
      end

      it 'works when assigning to a constant' do
        'FOO = bar'.
          must_be_parsed_as s(:casgn,
                              nil,
                              :FOO,
                              s(:send, nil, :bar))
      end

      it 'works when assigning to a collection element' do
        'foo[bar] = baz'.
          must_be_parsed_as s(:indexasgn,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar),
                              s(:send, nil, :baz))
      end

      it 'works when assigning to an attribute' do
        'foo.bar = baz'.
          must_be_parsed_as s(:send,
                              s(:send, nil, :foo),
                              :bar=,
                              s(:send, nil, :baz))
      end

      describe 'when assigning to a class variable' do
        it 'works outside a method' do
          '@@foo = bar'.
            must_be_parsed_as s(:cvdecl,
                                :@@foo,
                                s(:send, nil, :bar))
        end

        it 'works inside a method' do
          'def foo; @@bar = baz; end'.
            must_be_parsed_as s(:def,
                                :foo, s(:args),
                                s(:cvasgn, :@@bar, s(:send, nil, :baz)))
        end

        it 'works inside a method with a receiver' do
          'def self.foo; @@bar = baz; end'.
            must_be_parsed_as s(:defs,
                                s(:self),
                                :foo, s(:args),
                                s(:cvasgn, :@@bar, s(:send, nil, :baz)))
        end

        it 'works inside method arguments' do
          'def foo(bar = (@@baz = qux)); end'.
            must_be_parsed_as s(:def,
                                :foo,
                                s(:args,
                                  s(:lvasgn, :bar,
                                    s(:cvasgn, :@@baz, s(:send, nil, :qux)))),
                                nil)
        end

        it 'works inside method arguments of a singleton method' do
          'def self.foo(bar = (@@baz = qux)); end'.
            must_be_parsed_as s(:defs,
                                s(:self),
                                :foo,
                                s(:args,
                                  s(:lvasgn, :bar,
                                    s(:cvasgn, :@@baz, s(:send, nil, :qux)))),
                                nil)
        end
      end

      it 'works when assigning to a global variable' do
        '$foo = bar'.
          must_be_parsed_as s(:gasgn,
                              :$foo,
                              s(:send, nil, :bar))
      end
    end

    describe 'for multiple assignment' do
      specify do
        'foo, * = bar'.
          must_be_parsed_as s(:masgn,
                              s(:mlhs, s(:lvasgn, :foo), s(:splat)),
                              s(:send, nil, :bar))
      end

      specify do
        '(foo, *bar) = baz'.
          must_be_parsed_as s(:masgn,
                              s(:mlhs,
                                s(:lvasgn, :foo),
                                s(:splat, s(:lvasgn, :bar))),
                              s(:send, nil, :baz))
      end

      specify do
        '*foo, bar = baz'.
          must_be_parsed_as s(:masgn,
                              s(:mlhs,
                                s(:splat, s(:lvasgn, :foo)),
                                s(:lvasgn, :bar)),
                              s(:send, nil, :baz))
      end
    end

    describe 'for assignment to a collection element' do
      it 'handles multiple indices' do
        'foo[bar, baz] = qux'.
          must_be_parsed_as s(:indexasgn,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar),
                              s(:send, nil, :baz),
                              s(:send, nil, :qux))
      end
    end

    describe 'for operator assignment' do
      describe 'assigning to a collection element' do
        it 'handles multiple indices' do
          'foo[bar, baz] += qux'.
            must_be_parsed_as s(:op_asgn,
                                s(:indexasgn,
                                  s(:send, nil, :foo),
                                  s(:send, nil, :bar),
                                  s(:send, nil, :baz)), :+,
                                s(:send, nil, :qux))
        end

        it 'works with boolean operators' do
          'foo &&= bar'.
            must_be_parsed_as s(:and_asgn,
                                s(:lvasgn, :foo),
                                s(:send, nil, :bar))
        end

        it 'works with boolean operators and blocks' do
          'foo &&= begin; bar; end'.
            must_be_parsed_as s(:and_asgn,
                                s(:lvasgn, :foo),
                                s(:kwbegin,
                                  s(:send, nil, :bar)))
        end

        it 'works with arithmetic operators and blocks' do
          'foo += begin; bar; end'.
            must_be_parsed_as s(:lvasgn, :foo,
                                s(:send,
                                  s(:lvar, :foo), :+,
                                  s(:kwbegin,
                                    s(:send, nil, :bar))))
        end
      end
    end

    describe 'for multiple assignment' do
      describe 'with a right-hand splat' do
        specify do
          'foo, bar = *baz'.
            must_be_parsed_as s(:masgn,
                                s(:mlhs, s(:lvasgn, :foo), s(:lvasgn, :bar)),
                                s(:splat, s(:send, nil, :baz)))
        end
        specify do
          'foo, bar = baz, *qux'.
            must_be_parsed_as s(:masgn,
                                s(:mlhs, s(:lvasgn, :foo), s(:lvasgn, :bar)),
                                s(:array,
                                  s(:send, nil, :baz),
                                  s(:splat, s(:send, nil, :qux))))
        end
      end
    end
  end
end
