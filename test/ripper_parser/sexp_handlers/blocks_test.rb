# frozen_string_literal: true

require File.expand_path("../../test_helper.rb", File.dirname(__FILE__))

describe RipperParser::Parser do
  describe "#parse" do
    describe "for do blocks" do
      it "works with no statements in the block body" do
        _("foo do; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args), nil)
      end

      it "works with redo" do
        _("foo do; redo; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args),
                               s(:redo))
      end

      it "works with nested begin..end" do
        _("foo do; begin; bar; end; end;")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args),
                               s(:kwbegin, s(:send, nil, :bar)))
      end

      it "works with nested begin..end plus other statements" do
        _("foo do; bar; begin; baz; end; end;")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args),
                               s(:begin,
                                 s(:send, nil, :bar),
                                 s(:kwbegin, s(:send, nil, :baz))))
      end
    end

    describe "for brace blocks" do
      it "works with no statements in the block body" do
        _("foo { }")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args),
                               nil)
      end
    end

    describe "for block parameters" do
      specify do
        _("foo do |(bar, baz)| end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args,
                                 s(:procarg0,
                                   s(:arg, :bar),
                                   s(:arg, :baz))), nil)
      end

      specify do
        _("foo do |(bar, *baz)| end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args,
                                 s(:procarg0,
                                   s(:arg, :bar),
                                   s(:restarg, :baz))), nil)
      end

      specify do
        _("foo do |bar,*| end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args, s(:arg, :bar), s(:restarg)), nil)
      end

      specify do
        _("foo do |bar, &baz| end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args, s(:arg, :bar), s(:blockarg, :baz)), nil)
      end

      it "handles absent parameter specs" do
        _("foo do; bar; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args),
                               s(:send, nil, :bar))
      end

      it "handles empty parameter specs" do
        _("foo do ||; bar; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args),
                               s(:send, nil, :bar))
      end

      it "ignores a trailing comma in the block parameters" do
        _("foo do |bar, | end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args, s(:arg, :bar)), nil)
      end

      it "works with zero arguments" do
        _("foo do ||; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args), nil)
      end

      it "works with one argument" do
        _("foo do |bar|; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args, s(:procarg0, s(:arg, :bar))), nil)
      end

      it "works with multiple arguments" do
        _("foo do |bar, baz|; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args, s(:arg, :bar), s(:arg, :baz)), nil)
      end

      it "works with an argument with a default value" do
        _("foo do |bar=baz|; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args,
                                 s(:optarg, :bar, s(:send, nil, :baz))), nil)
      end

      it "works with a keyword argument with no default value" do
        _("foo do |bar:|; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args,
                                 s(:kwarg, :bar)), nil)
      end

      it "works with a keyword argument with a default value" do
        _("foo do |bar: baz|; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args,
                                 s(:kwoptarg, :bar, s(:send, nil, :baz))), nil)
      end

      it "works with a single splat argument" do
        _("foo do |*bar|; baz bar; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args, s(:restarg, :bar)),
                               s(:send, nil, :baz, s(:lvar, :bar)))
      end

      it "works with a combination of regular arguments and a splat argument" do
        _("foo do |bar, *baz|; qux bar, baz; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args, s(:arg, :bar), s(:restarg, :baz)),
                               s(:send, nil, :qux,
                                 s(:lvar, :bar),
                                 s(:lvar, :baz)))
      end

      it "works with a kwrest argument" do
        _("foo do |**bar|; baz bar; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args, s(:kwrestarg, :bar)),
                               s(:send, nil, :baz, s(:lvar, :bar)))
      end

      it "works with a nameless kwrest argument" do
        _("foo do |**|; bar; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args, s(:kwrestarg)),
                               s(:send, nil, :bar))
      end

      it "works with a regular argument after a splat argument" do
        _("foo do |*bar, baz|; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args, s(:restarg, :bar), s(:arg, :baz)),
                               nil)
      end

      it "works with a combination of regular arguments and a kwrest argument" do
        _("foo do |bar, **baz|; qux bar, baz; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args, s(:arg, :bar), s(:kwrestarg, :baz)),
                               s(:send, nil, :qux,
                                 s(:lvar, :bar),
                                 s(:lvar, :baz)))
      end

      it "works with a combination of regular arguments and an anonymous kwrest argument" do
        _("foo do |bar, **|; qux bar; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args,
                                 s(:arg, :bar),
                                 s(:kwrestarg)),
                               s(:send, nil, :qux,
                                 s(:lvar, :bar)))
      end

      it "works with one regular and one shadow argument" do
        _("foo do |bar; baz| end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args,
                                 s(:procarg0, s(:arg, :bar)),
                                 s(:shadowarg, :baz)),
                               nil)
      end

      it "works with several regular and one shadow argument" do
        _("foo do |bar, baz; qux| end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args,
                                 s(:arg, :bar),
                                 s(:arg, :baz),
                                 s(:shadowarg, :qux)),
                               nil)
      end

      it "works with numbered parameters" do
        _("foo { bar _1, _2 }")
          .must_be_parsed_as s(:numblock,
                               s(:send, nil, :foo), 2,
                               s(:send, nil, :bar,
                                 s(:lvar, :_1),
                                 s(:lvar, :_2)))
      end
    end

    describe "for begin" do
      it "works for an empty begin..end block" do
        _("begin end").must_be_parsed_as s(:kwbegin)
      end

      it "works for a simple begin..end block" do
        _("begin; foo; end").must_be_parsed_as s(:kwbegin,
                                                 s(:send, nil, :foo))
      end

      it "works for begin..end block with more than one statement" do
        _("begin; foo; bar; end")
          .must_be_parsed_as s(:kwbegin,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar))
      end

      it "keeps :kwbegin for the truepart of a postfix if" do
        _("begin; foo; end if bar")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :bar),
                               s(:kwbegin, s(:send, nil, :foo)),
                               nil)
      end

      it "keeps :kwbegin for the falsepart of a postfix unless" do
        _("begin; foo; end unless bar")
          .must_be_parsed_as s(:if,
                               s(:send, nil, :bar),
                               nil,
                               s(:kwbegin, s(:send, nil, :foo)))
      end

      it "keeps :kwbegin for a method receiver" do
        _("begin; foo; end.bar")
          .must_be_parsed_as s(:send,
                               s(:kwbegin, s(:send, nil, :foo)),
                               :bar)
      end
    end

    describe "for rescue/else" do
      it "works for a block with multiple rescue statements" do
        _("begin foo; rescue; bar; rescue; baz; end")
          .must_be_parsed_as s(:kwbegin,
                               s(:rescue,
                                 s(:send, nil, :foo),
                                 s(:resbody, nil, nil,
                                   s(:send, nil, :bar)),
                                 s(:resbody, nil, nil,
                                   s(:send, nil, :baz)), nil))
      end

      it "works for a block with rescue and else" do
        _("begin; foo; rescue; bar; else; baz; end")
          .must_be_parsed_as s(:kwbegin,
                               s(:rescue,
                                 s(:send, nil, :foo),
                                 s(:resbody, nil, nil,
                                   s(:send, nil, :bar)),
                                 s(:send, nil, :baz)))
      end

      it "works for a block with only else" do
        _("begin; foo; else; bar; end")
          .must_be_parsed_as s(:kwbegin,
                               s(:send, nil, :foo),
                               s(:begin,
                                 s(:send, nil, :bar)))
      end
    end

    describe "for the rescue statement" do
      it "works with assignment to an error variable" do
        _("begin; foo; rescue => bar; baz; end")
          .must_be_parsed_as s(:kwbegin,
                               s(:rescue,
                                 s(:send, nil, :foo),
                                 s(:resbody, nil,
                                   s(:lvasgn, :bar),
                                   s(:send, nil, :baz)), nil))
      end

      it "works with assignment of the exception to an instance variable" do
        _("begin; foo; rescue => @bar; baz; end")
          .must_be_parsed_as s(:kwbegin,
                               s(:rescue,
                                 s(:send, nil, :foo),
                                 s(:resbody, nil,
                                   s(:ivasgn, :@bar),
                                   s(:send, nil, :baz)), nil))
      end

      it "works with empty main and rescue bodies" do
        _("begin; rescue; end")
          .must_be_parsed_as s(:kwbegin,
                               s(:rescue, nil,
                                 s(:resbody, nil, nil, nil), nil))
      end

      it "works with single statement main and rescue bodies" do
        _("begin; foo; rescue; bar; end")
          .must_be_parsed_as s(:kwbegin,
                               s(:rescue,
                                 s(:send, nil, :foo),
                                 s(:resbody, nil, nil,
                                   s(:send, nil, :bar)), nil))
      end

      it "works with multi-statement main and rescue bodies" do
        _("begin; foo; bar; rescue; baz; qux; end")
          .must_be_parsed_as s(:kwbegin,
                               s(:rescue,
                                 s(:begin,
                                   s(:send, nil, :foo),
                                   s(:send, nil, :bar)),
                                 s(:resbody, nil, nil,
                                   s(:begin,
                                     s(:send, nil, :baz),
                                     s(:send, nil, :qux))), nil))
      end

      it "works with assignment to an error variable" do
        _("begin; foo; rescue => e; bar; end")
          .must_be_parsed_as s(:kwbegin,
                               s(:rescue,
                                 s(:send, nil, :foo),
                                 s(:resbody, nil, s(:lvasgn, :e),
                                   s(:send, nil, :bar)), nil))
      end

      it "works with filtering of the exception type" do
        _("begin; foo; rescue Bar; baz; end")
          .must_be_parsed_as s(:kwbegin,
                               s(:rescue,
                                 s(:send, nil, :foo),
                                 s(:resbody,
                                   s(:array, s(:const, nil, :Bar)), nil,
                                   s(:send, nil, :baz)), nil))
      end

      it "works with filtering of the exception type and assignment to an error variable" do
        _("begin; foo; rescue Bar => e; baz; end")
          .must_be_parsed_as s(:kwbegin,
                               s(:rescue,
                                 s(:send, nil, :foo),
                                 s(:resbody,
                                   s(:array,
                                     s(:const, nil, :Bar)),
                                   s(:lvasgn, :e),
                                   s(:send, nil, :baz)),
                                 nil))
      end

      it "works rescuing multiple exception types" do
        _("begin; foo; rescue Bar, Baz; qux; end")
          .must_be_parsed_as s(:kwbegin,
                               s(:rescue,
                                 s(:send, nil, :foo),
                                 s(:resbody,
                                   s(:array, s(:const, nil, :Bar), s(:const, nil, :Baz)),
                                   nil,
                                   s(:send, nil, :qux)),
                                 nil))
      end

      it "works rescuing a splatted list of exception types" do
        _("begin; foo; rescue *bar; baz; end")
          .must_be_parsed_as s(:kwbegin,
                               s(:rescue,
                                 s(:send, nil, :foo),
                                 s(:resbody,
                                   s(:array,
                                     s(:splat, s(:send, nil, :bar))), nil,
                                   s(:send, nil, :baz)), nil))
      end

      it "works rescuing a complex list of exception types" do
        _("begin; foo; rescue *bar, Baz; qux; end")
          .must_be_parsed_as s(:kwbegin,
                               s(:rescue,
                                 s(:send, nil, :foo),
                                 s(:resbody,
                                   s(:array,
                                     s(:splat, s(:send, nil, :bar)),
                                     s(:const, nil, :Baz)), nil,
                                   s(:send, nil, :qux)), nil))
      end

      it "works with a nested begin..end block" do
        _("begin; foo; rescue; begin; bar; end; end")
          .must_be_parsed_as s(:kwbegin,
                               s(:rescue,
                                 s(:send, nil, :foo),
                                 s(:resbody, nil, nil,
                                   s(:kwbegin,
                                     s(:send, nil, :bar))), nil))
      end

      it "works in a plain method body" do
        _("def foo; bar; rescue; baz; end")
          .must_be_parsed_as s(:def,
                               :foo,
                               s(:args),
                               s(:rescue,
                                 s(:send, nil, :bar),
                                 s(:resbody,
                                   nil, nil,
                                   s(:send, nil, :baz)), nil))
      end

      it "works in a method body inside begin..end with rescue" do
        _("def foo; bar; begin; baz; rescue; qux; end; quuz; end")
          .must_be_parsed_as s(:def,
                               :foo,
                               s(:args),
                               s(:begin,
                                 s(:send, nil, :bar),
                                 s(:kwbegin,
                                   s(:rescue,
                                     s(:send, nil, :baz),
                                     s(:resbody, nil, nil, s(:send, nil, :qux)), nil)),
                                 s(:send, nil, :quuz)))
      end

      it "works in a method body inside begin..end without rescue" do
        _("def foo; bar; begin; baz; qux; end; quuz; end")
          .must_be_parsed_as s(:def,
                               :foo,
                               s(:args),
                               s(:begin,
                                 s(:send, nil, :bar),
                                 s(:kwbegin,
                                   s(:send, nil, :baz),
                                   s(:send, nil, :qux)),
                                 s(:send, nil, :quuz)))
      end

      it "works in a method body fully inside begin..end" do
        _("def foo; begin; bar; baz; end; end")
          .must_be_parsed_as s(:def, :foo,
                               s(:args),
                               s(:kwbegin,
                                 s(:send, nil, :bar),
                                 s(:send, nil, :baz)))
      end
    end

    describe "for the postfix rescue modifier" do
      it "works in the basic case" do
        _("foo rescue bar")
          .must_be_parsed_as s(:rescue,
                               s(:send, nil, :foo),
                               s(:resbody, nil, nil,
                                 s(:send, nil, :bar)), nil)
      end

      it "works when the fallback value is a keyword" do
        _("foo rescue next")
          .must_be_parsed_as s(:rescue,
                               s(:send, nil, :foo),
                               s(:resbody, nil, nil,
                                 s(:next)), nil)
      end
    end

    describe "for the ensure statement" do
      it "works with single statement main and ensure bodies" do
        _("begin; foo; ensure; bar; end")
          .must_be_parsed_as s(:kwbegin,
                               s(:ensure,
                                 s(:send, nil, :foo),
                                 s(:send, nil, :bar)))
      end

      it "works with multi-statement main and ensure bodies" do
        _("begin; foo; bar; ensure; baz; qux; end")
          .must_be_parsed_as s(:kwbegin,
                               s(:ensure,
                                 s(:begin,
                                   s(:send, nil, :foo),
                                   s(:send, nil, :bar)),
                                 s(:begin,
                                   s(:send, nil, :baz),
                                   s(:send, nil, :qux))))
      end

      it "works together with rescue" do
        _("begin; foo; rescue; bar; ensure; baz; end")
          .must_be_parsed_as s(:kwbegin,
                               s(:ensure,
                                 s(:rescue,
                                   s(:send, nil, :foo),
                                   s(:resbody, nil, nil,
                                     s(:send, nil, :bar)),
                                   nil),
                                 s(:send, nil, :baz)))
      end

      it "works with empty main and ensure bodies" do
        _("begin; ensure; end")
          .must_be_parsed_as s(:kwbegin,
                               s(:ensure, nil, nil))
      end
    end

    describe "for the next statement" do
      it "works with no arguments" do
        _("foo do; next; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args),
                               s(:next))
      end

      it "works with one argument" do
        _("foo do; next bar; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args),
                               s(:next, s(:send, nil, :bar)))
      end

      it "works with a splat argument" do
        _("foo do; next *bar; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args),
                               s(:next,
                                 s(:splat,
                                   s(:send, nil, :bar))))
      end

      it "works with several arguments" do
        _("foo do; next bar, baz; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args),
                               s(:next,
                                 s(:send, nil, :bar),
                                 s(:send, nil, :baz)))
      end

      it "works with a function call with parentheses" do
        _("foo do; next foo(bar); end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args),
                               s(:next,
                                 s(:send, nil, :foo,
                                   s(:send, nil, :bar))))
      end

      it "works with a function call without parentheses" do
        _("foo do; next foo bar; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args),
                               s(:next,
                                 s(:send, nil, :foo,
                                   s(:send, nil, :bar))))
      end
    end

    describe "for the break statement" do
      it "works with break with no arguments" do
        _("foo do; break; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args),
                               s(:break))
      end

      it "works with break with one argument" do
        _("foo do; break bar; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args),
                               s(:break, s(:send, nil, :bar)))
      end

      it "works with a splat argument" do
        _("foo do; break *bar; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args),
                               s(:break,
                                 s(:splat,
                                   s(:send, nil, :bar))))
      end

      it "works with break with several arguments" do
        _("foo do; break bar, baz; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args),
                               s(:break,
                                 s(:send, nil, :bar),
                                 s(:send, nil, :baz)))
      end

      it "works with break with a function call with parentheses" do
        _("foo do; break foo(bar); end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args),
                               s(:break,
                                 s(:send, nil, :foo,
                                   s(:send, nil, :bar))))
      end

      it "works with break with a function call without parentheses" do
        _("foo do; break foo bar; end")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :foo),
                               s(:args),
                               s(:break,
                                 s(:send, nil, :foo,
                                   s(:send, nil, :bar))))
      end
    end

    describe "for lists of consecutive statments" do
      it "keeps extra blocks for grouped statements at the start of the list" do
        _("(foo; bar); baz")
          .must_be_parsed_as s(:begin,
                               s(:begin,
                                 s(:send, nil, :foo),
                                 s(:send, nil, :bar)),
                               s(:send, nil, :baz))
      end

      it "keeps extra blocks for grouped statements at the end of the list" do
        _("foo; (bar; baz)")
          .must_be_parsed_as s(:begin,
                               s(:send, nil, :foo),
                               s(:begin,
                                 s(:send, nil, :bar),
                                 s(:send, nil, :baz)))
      end
    end

    describe "for stabby lambda" do
      it "works in the simple case" do
        _("->(foo) { bar }")
          .must_be_parsed_as s(:block,
                               s(:lambda),
                               s(:args, s(:arg, :foo)),
                               s(:send, nil, :bar))
      end

      it "works in the simple case without parentheses" do
        _("-> foo { bar }")
          .must_be_parsed_as s(:block,
                               s(:lambda),
                               s(:args, s(:arg, :foo)),
                               s(:send, nil, :bar))
      end

      it "works when there are zero arguments" do
        _("->() { bar }")
          .must_be_parsed_as s(:block,
                               s(:lambda),
                               s(:args),
                               s(:send, nil, :bar))
      end

      it "works when there are no arguments" do
        _("-> { bar }")
          .must_be_parsed_as s(:block,
                               s(:lambda),
                               s(:args),
                               s(:send, nil, :bar))
      end

      it "works when there are no statements in the body" do
        _("->(foo) { }")
          .must_be_parsed_as s(:block,
                               s(:lambda),
                               s(:args, s(:arg, :foo)), nil)
      end

      it "works when there are several statements in the body" do
        _("->(foo) { bar; baz }")
          .must_be_parsed_as s(:block,
                               s(:lambda),
                               s(:args, s(:arg, :foo)),
                               s(:begin,
                                 s(:send, nil, :bar),
                                 s(:send, nil, :baz)))
      end

      it "works with numbered parameters" do
        _("-> { bar _1, _2 }").must_be_parsed_as \
          s(:numblock,
            s(:lambda), 2,
            s(:send, nil, :bar,
              s(:lvar, :_1),
              s(:lvar, :_2)))
      end

      it "sets line numbers correctly for lambdas with empty bodies" do
        _("->(foo) { }\nbar")
          .must_be_parsed_as s(:begin,
                               s(:block,
                                 s(:lambda).line(1),
                                 s(:args, s(:arg, :foo).line(1)).line(1),
                                 nil).line(1),
                               s(:send, nil, :bar).line(2)).line(1),
                             with_line_numbers: true
      end

      it "sets line numbers correctly for empty lambdas" do
        _("->() { }\nfoo")
          .must_be_parsed_as s(:begin,
                               s(:block,
                                 s(:lambda).line(1),
                                 s(:args).line(1),
                                 nil).line(1),
                               s(:send, nil, :foo).line(2)).line(1),
                             with_line_numbers: true
      end
    end

    describe "for lambda keyword" do
      it "works in the simple case" do
        _("lambda { |foo| bar }")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :lambda),
                               s(:args,
                                 s(:procarg0, s(:arg, :foo))),
                               s(:send, nil, :bar))
      end

      it "works with trailing argument comma" do
        _("lambda { |foo,| bar }")
          .must_be_parsed_as s(:block,
                               s(:send, nil, :lambda),
                               s(:args, s(:arg, :foo)),
                               s(:send, nil, :bar))
      end
    end
  end
end
