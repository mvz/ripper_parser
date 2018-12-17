require File.expand_path('../../test_helper.rb', File.dirname(__FILE__))

describe RipperParser::Parser do
  describe '#parse' do
    describe 'for do blocks' do
      it 'works with no statements in the block body' do
        'foo do; end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args), nil)
      end

      it 'works with redo' do
        'foo do; redo; end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args),
                              s(:redo))
      end

      it 'works with nested begin..end' do
        'foo do; begin; bar; end; end;'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args),
                              s(:kwbegin, s(:send, nil, :bar)))
      end

      it 'works with nested begin..end plus other statements' do
        'foo do; bar; begin; baz; end; end;'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args),
                              s(:block,
                                s(:send, nil, :bar),
                                s(:kwbegin, s(:send, nil, :baz))))
      end
    end

    describe 'for block parameters' do
      specify do
        'foo do |(bar, baz)| end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args,
                                s(:masgn, :bar, :baz)), nil)
      end

      specify do
        'foo do |(bar, *baz)| end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args,
                                s(:masgn, :bar, s(:restarg, :baz))), nil)
      end

      specify do
        'foo do |bar,*| end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args, s(:arg, :bar), s(:restarg)), nil)
      end

      specify do
        'foo do |bar, &baz| end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args, s(:arg, :bar), s(:blockarg, :baz)), nil)
      end

      it 'handles absent parameter specs' do
        'foo do; bar; end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args),
                              s(:send, nil, :bar))
      end

      it 'handles empty parameter specs' do
        'foo do ||; bar; end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args),
                              s(:send, nil, :bar))
      end

      it 'ignores a trailing comma in the block parameters' do
        'foo do |bar, | end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args, s(:arg, :bar)), nil)
      end

      it 'works with zero arguments' do
        'foo do ||; end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args), nil)
      end

      it 'works with one argument' do
        'foo do |bar|; end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args, s(:procarg0, :bar)), nil)
      end

      it 'works with multiple arguments' do
        'foo do |bar, baz|; end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args, s(:arg, :bar), s(:arg, :baz)), nil)
      end

      it 'works with a single splat argument' do
        'foo do |*bar|; end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args, s(:restarg, :bar)), nil)
      end

      it 'works with a combination of regular arguments and a splat argument' do
        'foo do |bar, *baz|; end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args, s(:arg, :bar), s(:restarg, :baz)), nil)
      end
    end

    describe 'for begin' do
      it 'works for an empty begin..end block' do
        'begin end'.must_be_parsed_as s(:kwbegin)
      end

      it 'works for a simple begin..end block' do
        'begin; foo; end'.must_be_parsed_as s(:kwbegin,
                                              s(:send, nil, :foo))
      end

      it 'works for begin..end block with more than one statement' do
        'begin; foo; bar; end'.
          must_be_parsed_as s(:kwbegin,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar))
      end

      it 'keeps :kwbegin for the argument of a unary operator' do
        '- begin; foo; end'.
          must_be_parsed_as s(:send,
                              s(:kwbegin, s(:send, nil, :foo)),
                              :-@)
      end

      it 'keeps :kwbegin for the first argument of a binary operator' do
        'begin; bar; end + foo'.
          must_be_parsed_as s(:send,
                              s(:kwbegin, s(:send, nil, :bar)),
                              :+,
                              s(:send, nil, :foo))
      end

      it 'keeps :kwbegin for the second argument of a binary operator' do
        'foo + begin; bar; end'.
          must_be_parsed_as s(:send,
                              s(:send, nil, :foo),
                              :+,
                              s(:kwbegin, s(:send, nil, :bar)))
      end

      it 'keeps :kwbegin for the first argument of a boolean operator' do
        'begin; bar; end and foo'.
          must_be_parsed_as s(:and,
                              s(:kwbegin, s(:send, nil, :bar)),
                              s(:send, nil, :foo))
      end

      it 'keeps :kwbegin for the second argument of a boolean operator' do
        'foo and begin; bar; end'.
          must_be_parsed_as s(:and,
                              s(:send, nil, :foo),
                              s(:kwbegin, s(:send, nil, :bar)))
      end

      it 'keeps :kwbegin for the first argument of a shift operator' do
        'begin; bar; end << foo'.
          must_be_parsed_as s(:send,
                              s(:kwbegin, s(:send, nil, :bar)),
                              :<<,
                              s(:send, nil, :foo))
      end

      it 'keeps :kwbegin for the second argument of a shift operator' do
        'foo >> begin; bar; end'.
          must_be_parsed_as s(:send,
                              s(:send, nil, :foo),
                              :>>,
                              s(:kwbegin, s(:send, nil, :bar)))
      end

      it 'keeps :kwbegin for the first argument of a ternary operator' do
        'begin; foo; end ? bar : baz'.
          must_be_parsed_as s(:if,
                              s(:kwbegin, s(:send, nil, :foo)),
                              s(:send, nil, :bar),
                              s(:send, nil, :baz))
      end

      it 'keeps :kwbegin for the second argument of a ternary operator' do
        'foo ? begin; bar; end : baz'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              s(:kwbegin, s(:send, nil, :bar)),
                              s(:send, nil, :baz))
      end

      it 'keeps :kwbegin for the third argument of a ternary operator' do
        'foo ? bar : begin; baz; end'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar),
                              s(:kwbegin, s(:send, nil, :baz)))
      end

      it 'keeps :kwbegin for the truepart of a postfix if' do
        'begin; foo; end if bar'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :bar),
                              s(:kwbegin, s(:send, nil, :foo)),
                              nil)
      end

      it 'keeps :kwbegin for the falsepart of a postfix unless' do
        'begin; foo; end unless bar'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :bar),
                              nil,
                              s(:kwbegin, s(:send, nil, :foo)))
      end

      it 'keeps :kwbegin for a method receiver' do
        'begin; foo; end.bar'.
          must_be_parsed_as s(:send,
                              s(:kwbegin, s(:send, nil, :foo)),
                              :bar)
      end
    end

    describe 'for rescue/else' do
      it 'works for a block with multiple rescue statements' do
        'begin foo; rescue; bar; rescue; baz; end'.
          must_be_parsed_as s(:kwbegin,
                              s(:rescue,
                                s(:send, nil, :foo),
                                s(:resbody,
                                  s(:array),
                                  s(:send, nil, :bar)),
                                s(:resbody,
                                  s(:array),
                                  s(:send, nil, :baz))))
      end

      it 'works for a block with rescue and else' do
        'begin; foo; rescue; bar; else; baz; end'.
          must_be_parsed_as s(:kwbegin,
                              s(:rescue,
                                s(:send, nil, :foo),
                                s(:resbody,
                                  s(:array),
                                  s(:send, nil, :bar)),
                                s(:send, nil, :baz)))
      end

      it 'works for a block with only else' do
        'begin; foo; else; bar; end'.
          must_be_parsed_as s(:kwbegin,
                              s(:send, nil, :foo),
                              s(:begin,
                                s(:send, nil, :bar)))
      end
    end

    describe 'for the rescue statement' do
      it 'works with assignment to an error variable' do
        'begin; foo; rescue => bar; baz; end'.
          must_be_parsed_as s(:kwbegin,
                              s(:rescue,
                                s(:send, nil, :foo),
                                s(:resbody,
                                  s(:array,
                                    s(:lvasgn, :bar, s(:gvar, :$!))),
                                  s(:send, nil, :baz))))
      end

      it 'works with assignment of the exception to an instance variable' do
        'begin; foo; rescue => @bar; baz; end'.
          must_be_parsed_as s(:kwbegin,
                              s(:rescue,
                                s(:send, nil, :foo),
                                s(:resbody,
                                  s(:array,
                                    s(:ivasgn, :@bar, s(:gvar, :$!))),
                                  s(:send, nil, :baz))))
      end

      it 'works with empty main and rescue bodies' do
        'begin; rescue; end'.
          must_be_parsed_as s(:kwbegin,
                              s(:rescue,
                                s(:resbody, s(:array), nil)))
      end

      it 'works with single statement main and rescue bodies' do
        'begin; foo; rescue; bar; end'.
          must_be_parsed_as s(:kwbegin,
                              s(:rescue,
                                s(:send, nil, :foo),
                                s(:resbody,
                                  s(:array),
                                  s(:send, nil, :bar))))
      end

      it 'works with multi-statement main and rescue bodies' do
        'begin; foo; bar; rescue; baz; qux; end'.
          must_be_parsed_as s(:kwbegin,
                              s(:rescue,
                                s(:block,
                                  s(:send, nil, :foo),
                                  s(:send, nil, :bar)),
                                s(:resbody,
                                  s(:array),
                                  s(:send, nil, :baz),
                                  s(:send, nil, :qux))))
      end

      it 'works with assignment to an error variable' do
        'begin; foo; rescue => e; bar; end'.
          must_be_parsed_as s(:kwbegin,
                              s(:rescue,
                                s(:send, nil, :foo),
                                s(:resbody,
                                  s(:array, s(:lvasgn, :e, s(:gvar, :$!))),
                                  s(:send, nil, :bar))))
      end

      it 'works with filtering of the exception type' do
        'begin; foo; rescue Bar; baz; end'.
          must_be_parsed_as s(:kwbegin,
                              s(:rescue,
                                s(:send, nil, :foo),
                                s(:resbody,
                                  s(:array, s(:const, nil, :Bar)),
                                  s(:send, nil, :baz))))
      end

      it 'works with filtering of the exception type and assignment to an error variable' do
        'begin; foo; rescue Bar => e; baz; end'.
          must_be_parsed_as s(:kwbegin,
                              s(:rescue,
                                s(:send, nil, :foo),
                                s(:resbody,
                                  s(:array,
                                    s(:const, nil, :Bar),
                                    s(:lvasgn, :e, s(:gvar, :$!))),
                                  s(:send, nil, :baz))))
      end

      it 'works rescuing multiple exception types' do
        'begin; foo; rescue Bar, Baz; qux; end'.
          must_be_parsed_as s(:kwbegin,
                              s(:rescue,
                                s(:send, nil, :foo),
                                s(:resbody,
                                  s(:array, s(:const, nil, :Bar), s(:const, nil, :Baz)),
                                  s(:send, nil, :qux))))
      end

      it 'works rescuing a splatted list of exception types' do
        'begin; foo; rescue *bar; baz; end'.
          must_be_parsed_as s(:kwbegin,
                              s(:rescue,
                                s(:send, nil, :foo),
                                s(:resbody,
                                  s(:splat, s(:send, nil, :bar)),
                                  s(:send, nil, :baz))))
      end

      it 'works rescuing a complex list of exception types' do
        'begin; foo; rescue *bar, Baz; qux; end'.
          must_be_parsed_as s(:kwbegin,
                              s(:rescue,
                                s(:send, nil, :foo),
                                s(:resbody,
                                  s(:array,
                                    s(:splat, s(:send, nil, :bar)),
                                    s(:const, nil, :Baz)),
                                  s(:send, nil, :qux))))
      end

      it 'works with a nested begin..end block' do
        'begin; foo; rescue; begin; bar; end; end'.
          must_be_parsed_as s(:kwbegin,
                              s(:rescue,
                                s(:send, nil, :foo),
                                s(:resbody, s(:array),
                                  s(:kwbegin,
                                    s(:send, nil, :bar)))))
      end

      it 'works in a plain method body' do
        'def foo; bar; rescue; baz; end'.
          must_be_parsed_as s(:def,
                              :foo,
                              s(:args),
                              s(:rescue,
                                s(:send, nil, :bar),
                                s(:resbody,
                                  s(:array),
                                  s(:send, nil, :baz))))
      end

      it 'works in a method body inside begin..end with rescue' do
        'def foo; bar; begin; baz; rescue; qux; end; quuz; end'.
          must_be_parsed_as s(:def,
                              :foo,
                              s(:args),
                              s(:send, nil, :bar),
                              s(:kwbegin,
                                s(:rescue,
                                  s(:send, nil, :baz),
                                  s(:resbody, s(:array), s(:send, nil, :qux)))),
                              s(:send, nil, :quuz))
      end

      it 'works in a method body inside begin..end without rescue' do
        'def foo; bar; begin; baz; qux; end; quuz; end'.
          must_be_parsed_as s(:def,
                              :foo,
                              s(:args),
                              s(:send, nil, :bar),
                              s(:kwbegin,
                                s(:send, nil, :baz),
                                s(:send, nil, :qux)),
                              s(:send, nil, :quuz))
      end

      it 'works in a method body fully inside begin..end' do
        'def foo; begin; bar; baz; end; end'.
          must_be_parsed_as s(:def, :foo,
                              s(:args),
                              s(:kwbegin,
                                s(:send, nil, :bar),
                                s(:send, nil, :baz)))
      end
    end

    describe 'for the postfix rescue modifier' do
      it 'works in the basic case' do
        'foo rescue bar'.
          must_be_parsed_as s(:rescue,
                              s(:send, nil, :foo),
                              s(:resbody,
                                s(:array),
                                s(:send, nil, :bar)))
      end

      it 'works when the fallback value is a keyword' do
        'foo rescue next'.
          must_be_parsed_as s(:rescue,
                              s(:send, nil, :foo),
                              s(:resbody,
                                s(:array),
                                s(:next)))
      end

      it 'works with assignment' do
        'foo = bar rescue baz'.
          must_be_parsed_as s(:lvasgn, :foo,
                              s(:rescue,
                                s(:send, nil, :bar),
                                s(:resbody, s(:array), s(:send, nil, :baz))))
      end

      it 'works with assignment with argument' do
        'foo = bar(baz) rescue qux'.
          must_be_parsed_as s(:lvasgn, :foo,
                              s(:rescue,
                                s(:send, nil, :bar, s(:send, nil, :baz)),
                                s(:resbody, s(:array), s(:send, nil, :qux))))
      end

      it 'works with assignment with argument without brackets' do
        expected = if RUBY_VERSION < '2.4.0'
                     s(:rescue,
                       s(:lvasgn, :foo, s(:send, nil, :bar, s(:send, nil, :baz))),
                       s(:resbody, s(:array), s(:send, nil, :qux)))
                   else
                     s(:lvasgn, :foo,
                       s(:rescue,
                         s(:send, nil, :bar, s(:send, nil, :baz)),
                         s(:resbody, s(:array), s(:send, nil, :qux))))
                   end
        'foo = bar baz rescue qux'.must_be_parsed_as expected
      end

      it 'works with assignment with class method call with argument without brackets' do
        expected = if RUBY_VERSION < '2.4.0'
                     s(:rescue,
                       s(:lvasgn, :foo, s(:send, s(:const, nil, :Bar), :baz, s(:send, nil, :qux))),
                       s(:resbody, s(:array), s(:send, nil, :quuz)))
                   else
                     s(:lvasgn, :foo,
                       s(:rescue,
                         s(:send, s(:const, nil, :Bar), :baz, s(:send, nil, :qux)),
                         s(:resbody, s(:array), s(:send, nil, :quuz))))
                   end
        'foo = Bar.baz qux rescue quuz'.
          must_be_parsed_as expected
      end

      it 'works with multiple assignment' do
        'foo, bar = baz rescue qux'.
          must_be_parsed_as s(:rescue,
                              s(:masgn,
                                s(:mlhs, s(:lvasgn, :foo), s(:lvasgn, :bar)),
                                s(:send, nil, :baz)),
                              s(:resbody, s(:array), s(:send, nil, :qux)))
      end
    end

    describe 'for the ensure statement' do
      it 'works with single statement main and ensure bodies' do
        'begin; foo; ensure; bar; end'.
          must_be_parsed_as s(:kwbegin,
                              s(:ensure,
                                s(:send, nil, :foo),
                                s(:send, nil, :bar)))
      end

      it 'works with multi-statement main and ensure bodies' do
        'begin; foo; bar; ensure; baz; qux; end'.
          must_be_parsed_as s(:kwbegin,
                              s(:ensure,
                                s(:block,
                                  s(:send, nil, :foo),
                                  s(:send, nil, :bar)),
                                s(:block,
                                  s(:send, nil, :baz),
                                  s(:send, nil, :qux))))
      end

      it 'works together with rescue' do
        'begin; foo; rescue; bar; ensure; baz; end'.
          must_be_parsed_as s(:kwbegin,
                              s(:ensure,
                                s(:rescue,
                                  s(:send, nil, :foo),
                                  s(:resbody,
                                    s(:array),
                                    s(:send, nil, :bar))),
                                s(:send, nil, :baz)))
      end

      it 'works with empty main and ensure bodies' do
        'begin; ensure; end'.
          must_be_parsed_as s(:kwbegin,
                              s(:ensure, s(:nil)))
      end
    end

    describe 'for the next statement' do
      it 'works with no arguments' do
        'foo do; next; end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args),
                              s(:next))
      end

      it 'works with one argument' do
        'foo do; next bar; end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args),
                              s(:next, s(:send, nil, :bar)))
      end

      it 'works with a splat argument' do
        'foo do; next *bar; end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args),
                              s(:next,
                                s(:svalue,
                                  s(:splat,
                                    s(:send, nil, :bar)))))
      end

      it 'works with several arguments' do
        'foo do; next bar, baz; end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args),
                              s(:next,
                                s(:array,
                                  s(:send, nil, :bar),
                                  s(:send, nil, :baz))))
      end

      it 'works with a function call with parentheses' do
        'foo do; next foo(bar); end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args),
                              s(:next,
                                s(:send, nil, :foo,
                                  s(:send, nil, :bar))))
      end

      it 'works with a function call without parentheses' do
        'foo do; next foo bar; end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args),
                              s(:next,
                                s(:send, nil, :foo,
                                  s(:send, nil, :bar))))
      end
    end

    describe 'for the break statement' do
      it 'works with break with no arguments' do
        'foo do; break; end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args),
                              s(:break))
      end

      it 'works with break with one argument' do
        'foo do; break bar; end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args),
                              s(:break, s(:send, nil, :bar)))
      end

      it 'works with a splat argument' do
        'foo do; break *bar; end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args),
                              s(:break,
                                s(:svalue,
                                  s(:splat,
                                    s(:send, nil, :bar)))))
      end

      it 'works with break with several arguments' do
        'foo do; break bar, baz; end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args),
                              s(:break,
                                s(:array,
                                  s(:send, nil, :bar),
                                  s(:send, nil, :baz))))
      end

      it 'works with break with a function call with parentheses' do
        'foo do; break foo(bar); end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args),
                              s(:break,
                                s(:send, nil, :foo,
                                  s(:send, nil, :bar))))
      end

      it 'works with break with a function call without parentheses' do
        'foo do; break foo bar; end'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:args),
                              s(:break,
                                s(:send, nil, :foo,
                                  s(:send, nil, :bar))))
      end
    end

    describe 'for lists of consecutive statments' do
      it 'removes extra blocks for grouped statements at the start of the list' do
        '(foo; bar); baz'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar),
                              s(:send, nil, :baz))
      end

      it 'keeps extra blocks for grouped statements at the end of the list' do
        'foo; (bar; baz)'.
          must_be_parsed_as s(:block,
                              s(:send, nil, :foo),
                              s(:block,
                                s(:send, nil, :bar),
                                s(:send, nil, :baz)))
      end
    end

    describe 'for stabby lambda' do
      it 'works in the simple case' do
        '->(foo) { bar }'.
          must_be_parsed_as s(:block,
                              s(:lambda),
                              s(:args, s(:arg, :foo)),
                              s(:send, nil, :bar))
      end

      it 'works when there are zero arguments' do
        '->() { bar }'.
          must_be_parsed_as s(:block,
                              s(:lambda),
                              s(:args),
                              s(:send, nil, :bar))
      end

      it 'works when there are no arguments' do
        '-> { bar }'.
          must_be_parsed_as s(:block,
                              s(:lambda),
                              s(:args),
                              s(:send, nil, :bar))
      end

      it 'works when there are no statements in the body' do
        '->(foo) { }'.
          must_be_parsed_as s(:block,
                              s(:lambda),
                              s(:args, s(:arg, :foo)), nil)
      end

      it 'works when there are several statements in the body' do
        '->(foo) { bar; baz }'.
          must_be_parsed_as s(:block,
                              s(:lambda),
                              s(:args, s(:arg, :foo)),
                              s(:block,
                                s(:send, nil, :bar),
                                s(:send, nil, :baz)))
      end
    end
  end
end
