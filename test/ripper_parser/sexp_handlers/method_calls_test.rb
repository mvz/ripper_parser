# frozen_string_literal: true

require File.expand_path("../../test_helper.rb", File.dirname(__FILE__))

describe RipperParser::Parser do
  describe "#parse" do
    describe "for method calls" do
      describe "without a receiver" do
        it "works without parentheses" do
          _("foo bar")
            .must_be_parsed_as s(:send, nil, :foo,
                                 s(:send, nil, :bar))
        end

        it "works with parentheses" do
          _("foo(bar)")
            .must_be_parsed_as s(:send, nil, :foo,
                                 s(:send, nil, :bar))
        end

        it "works with an empty parameter list and no parentheses" do
          _("foo")
            .must_be_parsed_as s(:send, nil, :foo)
        end

        it "works with parentheses around an empty parameter list" do
          _("foo()")
            .must_be_parsed_as s(:send, nil, :foo)
        end

        it "works for methods ending in a question mark" do
          _("foo?")
            .must_be_parsed_as s(:send, nil, :foo?)
        end

        it "works with nested calls without parentheses" do
          _("foo bar baz")
            .must_be_parsed_as s(:send, nil, :foo,
                                 s(:send, nil, :bar,
                                   s(:send, nil, :baz)))
        end

        it "works with a non-final splat argument" do
          _("foo(bar, *baz, qux)")
            .must_be_parsed_as s(:send,
                                 nil,
                                 :foo,
                                 s(:send, nil, :bar),
                                 s(:splat, s(:send, nil, :baz)),
                                 s(:send, nil, :qux))
        end

        it "works with a splat argument followed by several regular arguments" do
          _("foo(bar, *baz, qux, quuz)")
            .must_be_parsed_as s(:send,
                                 nil,
                                 :foo,
                                 s(:send, nil, :bar),
                                 s(:splat, s(:send, nil, :baz)),
                                 s(:send, nil, :qux),
                                 s(:send, nil, :quuz))
        end

        it "works with a named argument" do
          _("foo(bar, baz: qux)")
            .must_be_parsed_as s(:send,
                                 nil,
                                 :foo,
                                 s(:send, nil, :bar),
                                 s(:hash,
                                   s(:pair,
                                     s(:sym, :baz), s(:send, nil, :qux))))
        end

        it "works with several named arguments" do
          _("foo(bar, baz: qux, quux: quuz)")
            .must_be_parsed_as s(:send,
                                 nil,
                                 :foo,
                                 s(:send, nil, :bar),
                                 s(:hash,
                                   s(:pair, s(:sym, :baz), s(:send, nil, :qux)),
                                   s(:pair, s(:sym, :quux), s(:send, nil, :quuz))))
        end

        it "works with a double splat argument" do
          _("foo(bar, **baz)")
            .must_be_parsed_as s(:send,
                                 nil,
                                 :foo,
                                 s(:send, nil, :bar),
                                 s(:hash,
                                   s(:kwsplat, s(:send, nil, :baz))))
        end

        it "works with a named argument followed by a double splat argument" do
          _("foo(bar, baz: qux, **quuz)")
            .must_be_parsed_as s(:send,
                                 nil,
                                 :foo,
                                 s(:send, nil, :bar),
                                 s(:hash,
                                   s(:pair, s(:sym, :baz), s(:send, nil, :qux)),
                                   s(:kwsplat, s(:send, nil, :quuz))))
        end
      end

      describe "with a receiver" do
        it "works without parentheses" do
          _("foo.bar baz")
            .must_be_parsed_as s(:send,
                                 s(:send, nil, :foo),
                                 :bar,
                                 s(:send, nil, :baz))
        end

        it "works with parentheses" do
          _("foo.bar(baz)")
            .must_be_parsed_as s(:send,
                                 s(:send, nil, :foo),
                                 :bar,
                                 s(:send, nil, :baz))
        end

        it "works with parentheses around a call with no parentheses" do
          _("foo.bar(baz qux)")
            .must_be_parsed_as s(:send,
                                 s(:send, nil, :foo),
                                 :bar,
                                 s(:send, nil, :baz,
                                   s(:send, nil, :qux)))
        end

        it "works with nested calls without parentheses" do
          _("foo.bar baz qux")
            .must_be_parsed_as s(:send,
                                 s(:send, nil, :foo),
                                 :bar,
                                 s(:send, nil, :baz,
                                   s(:send, nil, :qux)))
        end

        it "keeps :begin around a method receiver" do
          _("begin; foo; end.bar")
            .must_be_parsed_as s(:send,
                                 s(:kwbegin,
                                   s(:send, nil, :foo)), :bar)
        end
      end

      describe "for collection indexing" do
        it "works in the simple case" do
          _("foo[bar]")
            .must_be_parsed_as s(:index,
                                 s(:send, nil, :foo),
                                 s(:send, nil, :bar))
        end

        it "works without any indexes" do
          _("foo[]").must_be_parsed_as s(:index,
                                         s(:send, nil, :foo))
        end

        it "works with self[]" do
          _("self[foo]").must_be_parsed_as s(:index,
                                             s(:self),
                                             s(:send, nil, :foo))
        end
      end

      describe "safe call" do
        it "works without arguments" do
          _("foo&.bar").must_be_parsed_as s(:csend, s(:send, nil, :foo), :bar)
        end

        it "works with arguments" do
          _("foo&.bar baz")
            .must_be_parsed_as s(:csend,
                                 s(:send, nil, :foo),
                                 :bar,
                                 s(:send, nil, :baz))
        end
      end

      describe "with blocks" do
        it "works for a do block" do
          _("foo.bar do baz; end")
            .must_be_parsed_as s(:block,
                                 s(:send,
                                   s(:send, nil, :foo),
                                   :bar),
                                 s(:args),
                                 s(:send, nil, :baz))
        end

        it "works for a do block with several statements" do
          _("foo.bar do baz; qux; end")
            .must_be_parsed_as s(:block,
                                 s(:send,
                                   s(:send, nil, :foo),
                                   :bar),
                                 s(:args),
                                 s(:begin,
                                   s(:send, nil, :baz),
                                   s(:send, nil, :qux)))
        end
      end
    end

    describe "for calls to super" do
      specify { _("super").must_be_parsed_as s(:zsuper) }
      specify do
        _("super foo").must_be_parsed_as s(:super,
                                           s(:send, nil, :foo))
      end
      specify do
        _("super foo, bar").must_be_parsed_as s(:super,
                                                s(:send, nil, :foo),
                                                s(:send, nil, :bar))
      end
      specify do
        _("super foo, *bar").must_be_parsed_as s(:super,
                                                 s(:send, nil, :foo),
                                                 s(:splat,
                                                   s(:send, nil, :bar)))
      end
      specify do
        _("super foo, *bar, &baz")
          .must_be_parsed_as s(:super,
                               s(:send, nil, :foo),
                               s(:splat, s(:send, nil, :bar)),
                               s(:block_pass, s(:send, nil, :baz)))
      end
    end

    it "handles calling a proc" do
      _("foo.()")
        .must_be_parsed_as s(:send, s(:send, nil, :foo), :call)
    end
  end
end
