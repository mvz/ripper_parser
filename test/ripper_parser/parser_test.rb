require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperParser::Parser do
  let(:parser) { RipperParser::Parser.new }
  describe '#parse' do
    it 'returns an s-expression' do
      result = parser.parse 'foo'
      result.must_be_instance_of Sexp
    end

    describe 'for an empty program' do
      it 'returns nil' do
        ''.must_be_parsed_as nil
      end
    end

    describe 'for a class declaration' do
      it 'works with a namespaced class name' do
        'class Foo::Bar; end'.
          must_be_parsed_as s(:class,
                              s(:const, s(:const, nil, :Foo), :Bar),
                              nil, nil)
      end

      it 'works for singleton classes' do
        'class << self; end'.must_be_parsed_as s(:sclass, s(:self), nil)
      end
    end

    describe 'for a module declaration' do
      it 'works with a simple module name' do
        'module Foo; end'.
          must_be_parsed_as s(:module, s(:const, nil, :Foo), nil)
      end

      it 'works with a namespaced module name' do
        'module Foo::Bar; end'.
          must_be_parsed_as s(:module,
                              s(:const, s(:const, nil, :Foo), :Bar), nil)
      end
    end

    describe 'for empty parentheses' do
      it 'works with lone ()' do
        '()'.must_be_parsed_as s(:nil)
      end
    end

    describe 'for the return statement' do
      it 'works with no arguments' do
        'return'.
          must_be_parsed_as s(:return)
      end

      it 'works with one argument' do
        'return foo'.
          must_be_parsed_as s(:return,
                              s(:send, nil, :foo))
      end

      it 'works with a splat argument' do
        'return *foo'.
          must_be_parsed_as s(:return,
                              s(:splat,
                                s(:send, nil, :foo)))
      end

      it 'works with multiple arguments' do
        'return foo, bar'.
          must_be_parsed_as s(:return,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar))
      end

      it 'works with a regular argument and a splat argument' do
        'return foo, *bar'.
          must_be_parsed_as s(:return,
                              s(:send, nil, :foo),
                              s(:splat,
                                s(:send, nil, :bar)))
      end

      it 'works with a function call with parentheses' do
        'return foo(bar)'.
          must_be_parsed_as s(:return,
                              s(:send, nil, :foo,
                                s(:send, nil, :bar)))
      end

      it 'works with a function call without parentheses' do
        'return foo bar'.
          must_be_parsed_as s(:return,
                              s(:send, nil, :foo,
                                s(:send, nil, :bar)))
      end
    end

    describe 'for the for statement' do
      it 'works with do' do
        'for foo in bar do; baz; end'.
          must_be_parsed_as s(:for,
                              s(:lvasgn, :foo),
                              s(:send, nil, :bar),
                              s(:send, nil, :baz))
      end

      it 'works without do' do
        'for foo in bar; baz; end'.
          must_be_parsed_as s(:for,
                              s(:lvasgn, :foo),
                              s(:send, nil, :bar),
                              s(:send, nil, :baz))
      end

      it 'works with an empty body' do
        'for foo in bar; end'.
          must_be_parsed_as s(:for,
                              s(:lvasgn, :foo),
                              s(:send, nil, :bar), nil)
      end
    end

    describe 'for a begin..end block' do
      it 'works with no statements' do
        'begin; end'.
          must_be_parsed_as s(:kwbegin)
      end

      it 'works with one statement' do
        'begin; foo; end'.
          must_be_parsed_as s(:kwbegin, s(:send, nil, :foo))
      end

      it 'works with multiple statements' do
        'begin; foo; bar; end'.
          must_be_parsed_as s(:kwbegin,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar))
      end
    end

    describe 'for arguments' do
      it 'works for a simple case with splat' do
        'foo *bar'.
          must_be_parsed_as s(:send,
                              nil,
                              :foo,
                              s(:splat, s(:send, nil, :bar)))
      end

      it 'works for a multi-argument case with splat' do
        'foo bar, *baz'.
          must_be_parsed_as s(:send,
                              nil,
                              :foo,
                              s(:send, nil, :bar),
                              s(:splat, s(:send, nil, :baz)))
      end

      it 'works for a simple case passing a block' do
        'foo &bar'.
          must_be_parsed_as s(:send, nil, :foo,
                              s(:block_pass,
                                s(:send, nil, :bar)))
      end

      it 'works for a bare hash' do
        'foo bar => baz'.
          must_be_parsed_as s(:send, nil, :foo,
                              s(:hash,
                                s(:pair,
                                  s(:send, nil, :bar),
                                  s(:send, nil, :baz))))
      end
    end

    describe 'for collection indexing' do
      it 'works in the simple case' do
        'foo[bar]'.
          must_be_parsed_as s(:index,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar))
      end

      it 'works without any indexes' do
        'foo[]'.must_be_parsed_as s(:index,
                                    s(:send, nil, :foo))
      end

      it 'works with self[]' do
        'self[foo]'.must_be_parsed_as s(:index,
                                        s(:self),
                                        s(:send, nil, :foo))
      end
    end

    describe 'for yield' do
      it 'works with no arguments and no parentheses' do
        'yield'.
          must_be_parsed_as s(:yield)
      end

      it 'works with parentheses but no arguments' do
        'yield()'.
          must_be_parsed_as s(:yield)
      end

      it 'works with one argument and no parentheses' do
        'yield foo'.
          must_be_parsed_as s(:yield, s(:send, nil, :foo))
      end

      it 'works with one argument and parentheses' do
        'yield(foo)'.
          must_be_parsed_as s(:yield, s(:send, nil, :foo))
      end

      it 'works with multiple arguments and no parentheses' do
        'yield foo, bar'.
          must_be_parsed_as s(:yield,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar))
      end

      it 'works with multiple arguments and parentheses' do
        'yield(foo, bar)'.
          must_be_parsed_as s(:yield,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar))
      end

      it 'works with splat' do
        'yield foo, *bar'.
          must_be_parsed_as s(:yield,
                              s(:send, nil, :foo),
                              s(:splat, s(:send, nil, :bar)))
      end

      it 'works with a function call with parentheses' do
        'yield foo(bar)'.
          must_be_parsed_as s(:yield,
                              s(:send, nil, :foo,
                                s(:send, nil, :bar)))
      end

      it 'works with a function call without parentheses' do
        'yield foo bar'.
          must_be_parsed_as s(:yield,
                              s(:send, nil, :foo,
                                s(:send, nil, :bar)))
      end
    end

    describe 'for the __ENCODING__ keyword' do
      it 'evaluates to the equivalent of Encoding::UTF_8' do
        '__ENCODING__'.
          must_be_parsed_as s(:const, s(:const, nil, :Encoding), :UTF_8)
      end
    end

    describe 'for the __FILE__ keyword' do
      describe 'when not passing a file name' do
        it "creates a string sexp with value '(string)'" do
          '__FILE__'.
            must_be_parsed_as s(:str, '(string)')
        end
      end

      describe 'when passing a file name' do
        it 'creates a string sexp with the file name' do
          result = parser.parse '__FILE__', 'foo'
          result.must_equal s(:str, 'foo')
        end
      end
    end

    describe 'for the __LINE__ keyword' do
      it 'creates a literal sexp with value of the line number' do
        '__LINE__'.
          must_be_parsed_as s(:int, 1)
        "\n__LINE__".
          must_be_parsed_as s(:int, 2)
      end
    end

    describe 'for the END keyword' do
      it 'converts to a :postexe iterator' do
        'END { foo }'.
          must_be_parsed_as s(:postexe, s(:send, nil, :foo))
      end

      it 'works with an empty block' do
        'END { }'.
          must_be_parsed_as s(:postexe, nil)
      end
    end

    describe 'for the BEGIN keyword' do
      it 'converts to a :preexe iterator' do
        'BEGIN { foo }'.
          must_be_parsed_as s(:preexe, s(:send, nil, :foo))
      end

      it 'works with an empty block' do
        'BEGIN { }'.
          must_be_parsed_as s(:preexe, nil)
      end
    end

    describe 'for constant lookups' do
      it 'works when explicitely starting from the root namespace' do
        '::Foo'.
          must_be_parsed_as s(:cbase, :Foo)
      end

      it 'works with a three-level constant lookup' do
        'Foo::Bar::Baz'.
          must_be_parsed_as s(:const,
                              s(:const, s(:const, nil, :Foo), :Bar),
                              :Baz)
      end

      it 'works looking up a constant in a non-constant' do
        'foo::Bar'.must_be_parsed_as s(:const,
                                       s(:send, nil, :foo),
                                       :Bar)
      end
    end

    describe 'for variable references' do
      it 'works for self' do
        'self'.
          must_be_parsed_as s(:self)
      end

      it 'works for instance variables' do
        '@foo'.
          must_be_parsed_as s(:ivar, :@foo)
      end

      it 'works for global variables' do
        '$foo'.
          must_be_parsed_as s(:gvar, :$foo)
      end

      it 'works for regexp match references' do
        '$1'.
          must_be_parsed_as s(:nth_ref, 1)
      end

      specify { "$'".must_be_parsed_as s(:back_ref, :"'") }
      specify { '$&'.must_be_parsed_as s(:back_ref, :"&") }

      it 'works for class variables' do
        '@@foo'.
          must_be_parsed_as s(:cvar, :@@foo)
      end
    end

    describe 'for operator assignment' do
      it 'works with +=' do
        'foo += bar'.
          must_be_parsed_as s(:lvasgn,
                              :foo,
                              s(:send,
                                s(:lvar, :foo),
                                :+,
                                s(:send, nil, :bar)))
      end

      it 'works with -=' do
        'foo -= bar'.
          must_be_parsed_as s(:lvasgn,
                              :foo,
                              s(:send,
                                s(:lvar, :foo),
                                :-,
                                s(:send, nil, :bar)))
      end

      it 'works with ||=' do
        'foo ||= bar'.
          must_be_parsed_as s(:or_asgn,
                              s(:lvasgn, :foo),
                              s(:send, nil, :bar))
      end

      it 'works when assigning to an instance variable' do
        '@foo += bar'.
          must_be_parsed_as s(:ivasgn,
                              :@foo,
                              s(:send,
                                s(:ivar, :@foo),
                                :+,
                                s(:send, nil, :bar)))
      end

      it 'works when assigning to a collection element' do
        'foo[bar] += baz'.
          must_be_parsed_as s(:op_asgn,
                              s(:indexasgn, s(:send, nil, :foo), s(:send, nil, :bar)),
                              :+,
                              s(:send, nil, :baz))
      end

      it 'works with ||= when assigning to a collection element' do
        'foo[bar] ||= baz'.
          must_be_parsed_as s(:or_asgn,
                              s(:indexasgn, s(:send, nil, :foo), s(:send, nil, :bar)),
                              s(:send, nil, :baz))
      end

      it 'works when assigning to an attribute' do
        'foo.bar += baz'.
          must_be_parsed_as s(:op_asgn,
                              s(:send, s(:send, nil, :foo), :bar),
                              :+,
                              s(:send, nil, :baz))
      end

      it 'works with ||= when assigning to an attribute' do
        'foo.bar ||= baz'.
          must_be_parsed_as s(:or_asgn,
                              s(:send, s(:send, nil, :foo), :bar),
                              s(:send, nil, :baz))
      end
    end

    describe 'for multiple assignment' do
      it 'works the same number of items on each side' do
        'foo, bar = baz, qux'.
          must_be_parsed_as s(:masgn,
                              s(:mlhs, s(:lvasgn, :foo), s(:lvasgn, :bar)),
                              s(:array,
                                s(:send, nil, :baz),
                                s(:send, nil, :qux)))
      end

      it 'works with a single item on the right-hand side' do
        'foo, bar = baz'.
          must_be_parsed_as s(:masgn,
                              s(:mlhs, s(:lvasgn, :foo), s(:lvasgn, :bar)),
                              s(:send, nil, :baz))
      end

      it 'works with left-hand splat' do
        'foo, *bar = baz, qux'.
          must_be_parsed_as s(:masgn,
                              s(:mlhs, s(:lvasgn, :foo), s(:splat, s(:lvasgn, :bar))),
                              s(:array,
                                s(:send, nil, :baz),
                                s(:send, nil, :qux)))
      end

      it 'works with parentheses around the left-hand side' do
        '(foo, bar) = baz'.
          must_be_parsed_as s(:masgn,
                              s(:mlhs, s(:lvasgn, :foo), s(:lvasgn, :bar)),
                              s(:send, nil, :baz))
      end

      it 'works with complex destructuring' do
        'foo, (bar, baz) = qux'.
          must_be_parsed_as s(:masgn,
                              s(:mlhs,
                                s(:lvasgn, :foo),
                                s(:mlhs, s(:lvasgn, :bar), s(:lvasgn, :baz))),
                              s(:send, nil, :qux))
      end

      it 'works with complex destructuring of the value' do
        'foo, (bar, baz) = [qux, [quz, quuz]]'.
          must_be_parsed_as s(:masgn,
                              s(:mlhs,
                                s(:lvasgn, :foo),
                                s(:mlhs, s(:lvasgn, :bar), s(:lvasgn, :baz))),
                              s(:array,
                                s(:send, nil, :qux),
                                s(:array,
                                  s(:send, nil, :quz),
                                  s(:send, nil, :quuz))))
      end

      it 'works with instance variables' do
        '@foo, @bar = baz'.
          must_be_parsed_as s(:masgn,
                              s(:mlhs, s(:ivasgn, :@foo), s(:ivasgn, :@bar)),
                              s(:send, nil, :baz))
      end

      it 'works with class variables' do
        '@@foo, @@bar = baz'.
          must_be_parsed_as s(:masgn,
                              s(:mlhs, s(:cvdecl, :@@foo), s(:cvdecl, :@@bar)),
                              s(:send, nil, :baz))
      end

      it 'works with attributes' do
        'foo.bar, foo.baz = qux'.
          must_be_parsed_as s(:masgn,
                              s(:mlhs,
                                s(:send, s(:send, nil, :foo), :bar=),
                                s(:send, s(:send, nil, :foo), :baz=)),
                              s(:send, nil, :qux))
      end

      it 'works with collection elements' do
        'foo[1], bar[2] = baz'.
          must_be_parsed_as s(:masgn,
                              s(:mlhs,
                                s(:indexasgn,
                                  s(:send, nil, :foo), s(:int, 1)),
                                s(:indexasgn,
                                  s(:send, nil, :bar), s(:int, 2))),
                              s(:send, nil, :baz))
      end

      it 'works with constants' do
        'Foo, Bar = baz'.
          must_be_parsed_as s(:masgn,
                              s(:mlhs, s(:casgn, nil, :Foo), s(:casgn, nil, :Bar)),
                              s(:send, nil, :baz))
      end

      it 'works with instance variables and splat' do
        '@foo, *@bar = baz'.
          must_be_parsed_as s(:masgn,
                              s(:mlhs,
                                s(:ivasgn, :@foo),
                                s(:splat, s(:ivasgn, :@bar))),
                              s(:send, nil, :baz))
      end
    end

    describe 'for operators' do
      it 'handles :!=' do
        'foo != bar'.
          must_be_parsed_as s(:send,
                              s(:send, nil, :foo),
                              :!=,
                              s(:send, nil, :bar))
      end

      it 'handles :=~ with two non-literals' do
        'foo =~ bar'.
          must_be_parsed_as s(:send,
                              s(:send, nil, :foo),
                              :=~,
                              s(:send, nil, :bar))
      end

      it 'handles :=~ with literal regexp on the left hand side' do
        '/foo/ =~ bar'.
          must_be_parsed_as s(:send,
                              s(:regexp, s(:str, 'foo'), s(:regopt)),
                              :=~,
                              s(:send, nil, :bar))
      end

      it 'handles :=~ with literal regexp on the right hand side' do
        'foo =~ /bar/'.
          must_be_parsed_as s(:send,
                              s(:send, nil, :foo),
                              :=~,
                              s(:regexp, s(:str, 'bar'), s(:regopt)))
      end

      it 'handles unary !' do
        '!foo'.
          must_be_parsed_as s(:send, s(:send, nil, :foo), :!)
      end

      it 'converts :not to :!' do
        'not foo'.
          must_be_parsed_as s(:send, s(:send, nil, :foo), :!)
      end

      it 'handles unary ! with a number literal' do
        '!1'.
          must_be_parsed_as s(:send, s(:int, 1), :!)
      end

      it 'handles the ternary operator' do
        'foo ? bar : baz'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar),
                              s(:send, nil, :baz))
      end
    end

    describe 'for expressions' do
      it 'handles assignment inside binary operator expressions' do
        'foo + (bar = baz)'.
          must_be_parsed_as s(:send,
                              s(:send, nil, :foo), :+,
                              s(:begin,
                                s(:lvasgn, :bar,
                                  s(:send, nil, :baz))))
      end

      it 'handles assignment inside unary operator expressions' do
        '+(foo = bar)'.
          must_be_parsed_as s(:send,
                              s(:begin,
                                s(:lvasgn, :foo, s(:send, nil, :bar))),
                              :+@)
      end
    end

    # Note: differences in the handling of comments are not caught by Sexp's
    # implementation of equality.
    describe 'for comments' do
      it 'handles method comments' do
        result = parser.parse "# Foo\ndef foo; end"
        result.must_equal s(:def,
                            :foo,
                            s(:args), nil)
        result.comments.must_equal "# Foo\n"
      end

      it 'handles comments for methods with explicit receiver' do
        result = parser.parse "# Foo\ndef foo.bar; end"
        result.must_equal s(:defs,
                            s(:send, nil, :foo),
                            :bar,
                            s(:args),
                            nil)
        result.comments.must_equal "# Foo\n"
      end

      it 'matches comments to the correct entity' do
        result = parser.parse "# Foo\nclass Foo\n# Bar\ndef bar\nend\nend"
        result.must_equal s(:class, s(:const, nil, :Foo), nil,
                            s(:def, :bar,
                              s(:args), nil))
        result.comments.must_equal "# Foo\n"
        defn = result[3]
        defn.sexp_type.must_equal :def
        defn.comments.must_equal "# Bar\n"
      end

      it 'combines multi-line comments' do
        result = parser.parse "# Foo\n# Bar\ndef foo; end"
        result.must_equal s(:def,
                            :foo,
                            s(:args), nil)
        result.comments.must_equal "# Foo\n# Bar\n"
      end

      it 'drops comments inside method bodies' do
        result = parser.parse <<-END
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
        END
        result.must_equal s(:class,
                            s(:const, nil, :Foo),
                            nil,
                            s(:begin,
                              s(:def, :foo, s(:args), s(:send, nil, :bar)),
                              s(:def, :bar, s(:args), s(:send, nil, :baz))))
        result.comments.must_equal "# Foo\n"
        result[3][1].comments.must_equal "# foo\n"
        result[3][2].comments.must_equal "# bar\n"
      end

      it 'handles the use of symbols that are keywords' do
        result = parser.parse "# Foo\ndef bar\n:class\nend"
        result.must_equal s(:def,
                            :bar,
                            s(:args),
                            s(:sym, :class))
        result.comments.must_equal "# Foo\n"
      end

      it 'handles use of singleton class inside methods' do
        result = parser.parse "# Foo\ndef bar\nclass << self\nbaz\nend\nend"
        result.must_equal s(:def,
                            :bar,
                            s(:args),
                            s(:sclass, s(:self),
                              s(:send, nil, :baz)))
        result.comments.must_equal "# Foo\n"
      end
    end

    # Note: differences in the handling of line numbers are not caught by
    # Sexp's implementation of equality.
    describe 'assigning line numbers' do
      it 'works for a plain method call' do
        result = parser.parse 'foo'
        result.line.must_equal 1
      end

      it 'works for a method call with parentheses' do
        result = parser.parse 'foo()'
        result.line.must_equal 1
      end

      it 'works for a method call with receiver' do
        result = parser.parse 'foo.bar'
        result.line.must_equal 1
      end

      it 'works for a method call with receiver and arguments' do
        result = parser.parse 'foo.bar baz'
        result.line.must_equal 1
      end

      it 'works for a method call with arguments' do
        result = parser.parse 'foo bar'
        result.line.must_equal 1
      end

      it 'works for a block with two lines' do
        result = parser.parse "foo\nbar\n"
        result.sexp_type.must_equal :begin
        result[1].line.must_equal 1
        result[2].line.must_equal 2
        result.line.must_equal 1
      end

      it 'works for a constant reference' do
        result = parser.parse 'Foo'
        result.line.must_equal 1
      end

      it 'works for an instance variable' do
        result = parser.parse '@foo'
        result.line.must_equal 1
      end

      it 'works for a global variable' do
        result = parser.parse '$foo'
        result.line.must_equal 1
      end

      it 'works for a class variable' do
        result = parser.parse '@@foo'
        result.line.must_equal 1
      end

      it 'works for a local variable' do
        result = parser.parse "foo = bar\nfoo\n"
        result.sexp_type.must_equal :begin
        result[1].line.must_equal 1
        result[2].line.must_equal 2
        result.line.must_equal 1
      end

      it 'works for an integer literal' do
        result = parser.parse '42'
        result.line.must_equal 1
      end

      it 'works for a float literal' do
        result = parser.parse '3.14'
        result.line.must_equal 1
      end

      it 'works for a regular expression back reference' do
        result = parser.parse '$1'
        result.line.must_equal 1
      end

      it 'works for self' do
        result = parser.parse 'self'
        result.line.must_equal 1
      end

      it 'works for __FILE__' do
        result = parser.parse '__FILE__'
        result.line.must_equal 1
      end

      it 'works for nil' do
        result = parser.parse 'nil'
        result.line.must_equal 1
      end

      it 'works for a symbol literal' do
        result = parser.parse ':foo'
        result.line.must_equal 1
      end

      it 'works for a class definition' do
        result = parser.parse 'class Foo; end'
        result.line.must_equal 1
      end

      it 'works for a module definition' do
        result = parser.parse 'module Foo; end'
        result.line.must_equal 1
      end

      it 'works for a method definition' do
        result = parser.parse 'def foo; end'
        result.line.must_equal 1
      end

      it 'works for assignment of the empty hash' do
        result = parser.parse 'foo = {}'
        result.line.must_equal 1
      end

      it 'works for multiple assignment of empty hashes' do
        result = parser.parse 'foo, bar = {}, {}'
        result.line.must_equal 1
      end

      it 'assigns line numbers to nested sexps without their own line numbers' do
        result = parser.parse "foo(bar) do\nnext baz\nend\n"
        result.must_equal s(:block,
                            s(:send, nil, :foo, s(:send, nil, :bar)),
                            s(:args),
                            s(:next, s(:send, nil, :baz)))
        arglist = result[1][3]
        block = result[3]
        nums = [arglist.line, block.line]
        nums.must_equal [1, 2]
      end

      describe 'when a line number is passed' do
        it 'shifts all line numbers as appropriate' do
          result = parser.parse "foo\nbar\n", '(string)', 3
          result.must_equal s(:begin,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar))
          result.line.must_equal 3
          result[1].line.must_equal 3
          result[2].line.must_equal 4
        end
      end
    end
  end

  describe '#trickle_up_line_numbers' do
    it 'works through several nested levels' do
      inner = s(:foo)
      outer = s(:bar, s(:baz, s(:qux, inner)))
      outer.line = 42
      parser.send :trickle_down_line_numbers, outer
      inner.line.must_equal 42
    end
  end

  describe '#trickle_down_line_numbers' do
    it 'works through several nested levels' do
      inner = s(:foo)
      inner.line = 42
      outer = s(:bar, s(:baz, s(:qux, inner)))
      parser.send :trickle_up_line_numbers, outer
      outer.line.must_equal 42
    end
  end
end
