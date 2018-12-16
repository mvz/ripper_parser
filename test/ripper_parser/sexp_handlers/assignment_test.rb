require File.expand_path('../../test_helper.rb', File.dirname(__FILE__))

describe RipperParser::Parser do
  describe '#parse' do
    describe 'for single assignment' do
      it 'works when assigning to a namespaced constant' do
        'Foo::Bar = baz'.
          must_be_parsed_as s(:casgn,
                              s(:colon2, s(:const, nil, :Foo), :Bar),
                              s(:call, nil, :baz))
      end

      it 'works when assigning to constant in the root namespace' do
        '::Foo = bar'.
          must_be_parsed_as s(:casgn,
                              s(:colon3, :Foo),
                              s(:call, nil, :bar))
      end

      it 'works with blocks' do
        'foo = begin; bar; end'.
          must_be_parsed_as s(:lasgn, :foo, s(:call, nil, :bar))
      end

      describe 'with a right-hand splat' do
        it 'works in the simple case' do
          'foo = *bar'.
            must_be_parsed_as s(:lasgn, :foo,
                                s(:svalue,
                                  s(:splat,
                                    s(:call, nil, :bar))))
        end

        it 'works with blocks' do
          'foo = *begin; bar; end'.
            must_be_parsed_as s(:lasgn, :foo,
                                s(:svalue, s(:splat, s(:call, nil, :bar))))
        end
      end

      describe 'with several items on the right hand side' do
        it 'works in the simple case' do
          'foo = bar, baz'.
            must_be_parsed_as s(:lasgn, :foo,
                                s(:svalue,
                                  s(:array,
                                    s(:call, nil, :bar),
                                    s(:call, nil, :baz))))
        end

        it 'works with a splat' do
          'foo = bar, *baz'.
            must_be_parsed_as s(:lasgn, :foo,
                                s(:svalue,
                                  s(:array,
                                    s(:call, nil, :bar),
                                    s(:splat,
                                      s(:call, nil, :baz)))))
        end
      end

      describe 'with an array literal on the right hand side' do
        specify do
          'foo = [bar, baz]'.
            must_be_parsed_as s(:lasgn, :foo,
                                s(:array,
                                  s(:call, nil, :bar),
                                  s(:call, nil, :baz)))
        end
      end

      it 'works when assigning to an instance variable' do
        '@foo = bar'.
          must_be_parsed_as s(:iasgn,
                              :@foo,
                              s(:call, nil, :bar))
      end

      it 'works when assigning to a constant' do
        'FOO = bar'.
          must_be_parsed_as s(:casgn,
                              nil,
                              :FOO,
                              s(:call, nil, :bar))
      end

      it 'works when assigning to a collection element' do
        'foo[bar] = baz'.
          must_be_parsed_as s(:attrasgn,
                              s(:call, nil, :foo),
                              :[]=,
                              s(:call, nil, :bar),
                              s(:call, nil, :baz))
      end

      it 'works when assigning to an attribute' do
        'foo.bar = baz'.
          must_be_parsed_as s(:attrasgn,
                              s(:call, nil, :foo),
                              :bar=,
                              s(:call, nil, :baz))
      end

      describe 'when assigning to a class variable' do
        it 'works outside a method' do
          '@@foo = bar'.
            must_be_parsed_as s(:cvdecl,
                                :@@foo,
                                s(:call, nil, :bar))
        end

        it 'works inside a method' do
          'def foo; @@bar = baz; end'.
            must_be_parsed_as s(:defn,
                                :foo, s(:args),
                                s(:cvasgn, :@@bar, s(:call, nil, :baz)))
        end

        it 'works inside a method with a receiver' do
          'def self.foo; @@bar = baz; end'.
            must_be_parsed_as s(:defs,
                                s(:self),
                                :foo, s(:args),
                                s(:cvasgn, :@@bar, s(:call, nil, :baz)))
        end

        it 'works inside method arguments' do
          'def foo(bar = (@@baz = qux)); end'.
            must_be_parsed_as s(:defn,
                                :foo,
                                s(:args,
                                  s(:lasgn, :bar,
                                    s(:cvasgn, :@@baz, s(:call, nil, :qux)))),
                                s(:nil))
        end

        it 'works inside method arguments of a singleton method' do
          'def self.foo(bar = (@@baz = qux)); end'.
            must_be_parsed_as s(:defs,
                                s(:self),
                                :foo,
                                s(:args,
                                  s(:lasgn, :bar,
                                    s(:cvasgn, :@@baz, s(:call, nil, :qux)))),
                                s(:nil))
        end
      end

      it 'works when assigning to a global variable' do
        '$foo = bar'.
          must_be_parsed_as s(:gasgn,
                              :$foo,
                              s(:call, nil, :bar))
      end
    end

    describe 'for multiple assignment' do
      specify do
        'foo, * = bar'.
          must_be_parsed_as s(:masgn,
                              s(:array, s(:lasgn, :foo), s(:splat)),
                              s(:to_ary, s(:call, nil, :bar)))
      end

      specify do
        '(foo, *bar) = baz'.
          must_be_parsed_as s(:masgn,
                              s(:array,
                                s(:lasgn, :foo),
                                s(:splat, s(:lasgn, :bar))),
                              s(:to_ary, s(:call, nil, :baz)))
      end

      specify do
        '*foo, bar = baz'.
          must_be_parsed_as s(:masgn,
                              s(:array,
                                s(:splat, s(:lasgn, :foo)),
                                s(:lasgn, :bar)),
                              s(:to_ary, s(:call, nil, :baz)))
      end
    end

    describe 'for assignment to a collection element' do
      it 'handles multiple indices' do
        'foo[bar, baz] = qux'.
          must_be_parsed_as s(:attrasgn,
                              s(:call, nil, :foo),
                              :[]=,
                              s(:call, nil, :bar),
                              s(:call, nil, :baz),
                              s(:call, nil, :qux))
      end
    end

    describe 'for operator assignment' do
      describe 'assigning to a collection element' do
        it 'handles multiple indices' do
          'foo[bar, baz] += qux'.
            must_be_parsed_as s(:op_asgn1,
                                s(:call, nil, :foo),
                                s(:arglist,
                                  s(:call, nil, :bar),
                                  s(:call, nil, :baz)),
                                :+,
                                s(:call, nil, :qux))
        end

        it 'works with boolean operators' do
          'foo &&= bar'.
            must_be_parsed_as s(:op_asgn_and,
                                s(:lvar, :foo), s(:lasgn, :foo, s(:call, nil, :bar)))
        end

        it 'works with boolean operators and blocks' do
          'foo &&= begin; bar; end'.
            must_be_parsed_as s(:op_asgn_and,
                                s(:lvar, :foo), s(:lasgn, :foo, s(:call, nil, :bar)))
        end

        it 'works with arithmetic operators and blocks' do
          'foo += begin; bar; end'.
            must_be_parsed_as s(:lasgn, :foo,
                                s(:call, s(:lvar, :foo), :+, s(:call, nil, :bar)))
        end
      end
    end

    describe 'for multiple assignment' do
      describe 'with a right-hand splat' do
        specify do
          'foo, bar = *baz'.
            must_be_parsed_as s(:masgn,
                                s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                                s(:splat, s(:call, nil, :baz)))
        end
        specify do
          'foo, bar = baz, *qux'.
            must_be_parsed_as s(:masgn,
                                s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                                s(:array,
                                  s(:call, nil, :baz),
                                  s(:splat, s(:call, nil, :qux))))
        end
      end
    end
  end
end
