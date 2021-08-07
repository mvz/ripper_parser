# frozen_string_literal: true

require File.expand_path("../../test_helper.rb", File.dirname(__FILE__))

describe RipperParser::Parser do
  describe "#parse" do
    describe "for single assignment" do
      it "works when assigning to a namespaced constant" do
        _("Foo::Bar = baz")
          .must_be_parsed_as s(:casgn,
                               s(:const, s(:const, nil, :Foo), :Bar),
                               s(:send, nil, :baz))
      end

      it "works when assigning to constant in the root namespace" do
        _("::Foo = bar")
          .must_be_parsed_as s(:casgn,
                               s(:cbase), :Foo,
                               s(:send, nil, :bar))
      end

      it "works with blocks" do
        _("foo = begin; bar; end")
          .must_be_parsed_as s(:lvasgn, :foo, s(:kwbegin, s(:send, nil, :bar)))
      end

      describe "with a right-hand splat" do
        it "works in the simple case" do
          _("foo = *bar")
            .must_be_parsed_as s(:lvasgn, :foo,
                                 s(:array,
                                   s(:splat,
                                     s(:send, nil, :bar))))
        end

        it "works with blocks" do
          _("foo = *begin; bar; end")
            .must_be_parsed_as s(:lvasgn, :foo,
                                 s(:array,
                                   s(:splat,
                                     s(:kwbegin,
                                       s(:send, nil, :bar)))))
        end
      end

      describe "with several items on the right hand side" do
        it "works in the simple case" do
          _("foo = bar, baz")
            .must_be_parsed_as s(:lvasgn, :foo,
                                 s(:array,
                                   s(:send, nil, :bar),
                                   s(:send, nil, :baz)))
        end

        it "works with a splat" do
          _("foo = bar, *baz")
            .must_be_parsed_as s(:lvasgn, :foo,
                                 s(:array,
                                   s(:send, nil, :bar),
                                   s(:splat,
                                     s(:send, nil, :baz))))
        end
      end

      describe "with an array literal on the right hand side" do
        specify do
          _("foo = [bar, baz]")
            .must_be_parsed_as s(:lvasgn, :foo,
                                 s(:array,
                                   s(:send, nil, :bar),
                                   s(:send, nil, :baz)))
        end
      end

      it "works when assigning to an instance variable" do
        _("@foo = bar")
          .must_be_parsed_as s(:ivasgn,
                               :@foo,
                               s(:send, nil, :bar))
      end

      it "works when assigning to a constant" do
        _("FOO = bar")
          .must_be_parsed_as s(:casgn,
                               nil,
                               :FOO,
                               s(:send, nil, :bar))
      end

      it "works when assigning to a collection element" do
        _("foo[bar] = baz")
          .must_be_parsed_as s(:indexasgn,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar),
                               s(:send, nil, :baz))
      end

      it "works when assigning to an attribute" do
        _("foo.bar = baz")
          .must_be_parsed_as s(:send,
                               s(:send, nil, :foo),
                               :bar=,
                               s(:send, nil, :baz))
      end

      it "works when safe-assigning to an attribute" do
        _("foo&.bar = baz")
          .must_be_parsed_as s(:csend,
                               s(:send, nil, :foo),
                               :bar=,
                               s(:send, nil, :baz))
      end

      describe "when assigning to a class variable" do
        it "works outside a method" do
          _("@@foo = bar")
            .must_be_parsed_as s(:cvasgn,
                                 :@@foo,
                                 s(:send, nil, :bar))
        end

        it "works inside a method" do
          _("def foo; @@bar = baz; end")
            .must_be_parsed_as s(:def,
                                 :foo, s(:args),
                                 s(:cvasgn, :@@bar, s(:send, nil, :baz)))
        end

        it "works inside a method with a receiver" do
          _("def self.foo; @@bar = baz; end")
            .must_be_parsed_as s(:defs,
                                 s(:self),
                                 :foo, s(:args),
                                 s(:cvasgn, :@@bar, s(:send, nil, :baz)))
        end

        it "works inside method arguments" do
          _("def foo(bar = (@@baz = qux)); end")
            .must_be_parsed_as s(:def,
                                 :foo,
                                 s(:args,
                                   s(:optarg, :bar,
                                     s(:begin,
                                       s(:cvasgn, :@@baz, s(:send, nil, :qux))))),
                                 nil)
        end

        it "works inside method arguments of a singleton method" do
          _("def self.foo(bar = (@@baz = qux)); end")
            .must_be_parsed_as s(:defs,
                                 s(:self), :foo,
                                 s(:args,
                                   s(:optarg, :bar,
                                     s(:begin,
                                       s(:cvasgn, :@@baz, s(:send, nil, :qux))))),
                                 nil)
        end

        it "works inside the receiver in a method definition" do
          _("def (bar = (@@baz = qux)).foo; end")
            .must_be_parsed_as s(:defs,
                                 s(:lvasgn, :bar,
                                   s(:begin,
                                     s(:cvasgn, :@@baz,
                                       s(:send, nil, :qux)))), :foo,
                                 s(:args), nil)
        end
      end

      it "works when assigning to a global variable" do
        _("$foo = bar")
          .must_be_parsed_as s(:gvasgn,
                               :$foo,
                               s(:send, nil, :bar))
      end

      describe "with a rescue modifier" do
        it "works with assigning a bare method call" do
          _("foo = bar rescue baz")
            .must_be_parsed_as s(:lvasgn, :foo,
                                 s(:rescue,
                                   s(:send, nil, :bar),
                                   s(:resbody, nil, nil, s(:send, nil, :baz)), nil))
        end

        it "works with a method call with argument" do
          _("foo = bar(baz) rescue qux")
            .must_be_parsed_as s(:lvasgn, :foo,
                                 s(:rescue,
                                   s(:send, nil, :bar, s(:send, nil, :baz)),
                                   s(:resbody, nil, nil, s(:send, nil, :qux)), nil))
        end

        it "works with a method call with argument without brackets" do
          _("foo = bar baz rescue qux")
            .must_be_parsed_as s(:lvasgn, :foo,
                                 s(:rescue,
                                   s(:send, nil, :bar, s(:send, nil, :baz)),
                                   s(:resbody, nil, nil, s(:send, nil, :qux)), nil))
        end

        it "works with a class method call with argument without brackets" do
          _("foo = Bar.baz qux rescue quuz")
            .must_be_parsed_as s(:lvasgn, :foo,
                                 s(:rescue,
                                   s(:send,
                                     s(:const, nil, :Bar),
                                     :baz,
                                     s(:send, nil, :qux)),
                                   s(:resbody, nil, nil, s(:send, nil, :quuz)), nil))
        end
      end

      it "sets the correct line numbers" do
        _("foo = {}")
          .must_be_parsed_as s(:lvasgn, :foo, s(:hash).line(1)).line(1),
                             with_line_numbers: true
      end
    end

    describe "for multiple assignment" do
      specify do
        _("foo, * = bar")
          .must_be_parsed_as s(:masgn,
                               s(:mlhs, s(:lvasgn, :foo), s(:splat)),
                               s(:send, nil, :bar))
      end

      specify do
        _("(foo, *bar) = baz")
          .must_be_parsed_as s(:masgn,
                               s(:mlhs,
                                 s(:lvasgn, :foo),
                                 s(:splat, s(:lvasgn, :bar))),
                               s(:send, nil, :baz))
      end

      specify do
        _("*foo, bar = baz")
          .must_be_parsed_as s(:masgn,
                               s(:mlhs,
                                 s(:splat, s(:lvasgn, :foo)),
                                 s(:lvasgn, :bar)),
                               s(:send, nil, :baz))
      end

      it "works with blocks" do
        _("foo, bar = begin; baz; end")
          .must_be_parsed_as s(:masgn,
                               s(:mlhs, s(:lvasgn, :foo), s(:lvasgn, :bar)),
                               s(:kwbegin, s(:send, nil, :baz)))
      end

      it "works with a rescue modifier" do
        expected = if RUBY_VERSION < "2.7.0"
                     s(:rescue,
                       s(:masgn,
                         s(:mlhs, s(:lvasgn, :foo), s(:lvasgn, :bar)),
                         s(:send, nil, :baz)),
                       s(:resbody, nil, nil, s(:send, nil, :qux)), nil)
                   else
                     s(:masgn,
                       s(:mlhs, s(:lvasgn, :foo), s(:lvasgn, :bar)),
                       s(:rescue,
                         s(:send, nil, :baz),
                         s(:resbody, nil, nil, s(:send, nil, :qux)), nil))
                   end

        _("foo, bar = baz rescue qux")
          .must_be_parsed_as expected
      end

      it "works the same number of items on each side" do
        _("foo, bar = baz, qux")
          .must_be_parsed_as s(:masgn,
                               s(:mlhs, s(:lvasgn, :foo), s(:lvasgn, :bar)),
                               s(:array,
                                 s(:send, nil, :baz),
                                 s(:send, nil, :qux)))
      end

      it "works with a single item on the right-hand side" do
        _("foo, bar = baz")
          .must_be_parsed_as s(:masgn,
                               s(:mlhs, s(:lvasgn, :foo), s(:lvasgn, :bar)),
                               s(:send, nil, :baz))
      end

      it "works with left-hand splat" do
        _("foo, *bar = baz, qux")
          .must_be_parsed_as s(:masgn,
                               s(:mlhs, s(:lvasgn, :foo), s(:splat, s(:lvasgn, :bar))),
                               s(:array,
                                 s(:send, nil, :baz),
                                 s(:send, nil, :qux)))
      end

      it "works with parentheses around the left-hand side" do
        _("(foo, bar) = baz")
          .must_be_parsed_as s(:masgn,
                               s(:mlhs, s(:lvasgn, :foo), s(:lvasgn, :bar)),
                               s(:send, nil, :baz))
      end

      it "works with complex destructuring" do
        _("foo, (bar, baz) = qux")
          .must_be_parsed_as s(:masgn,
                               s(:mlhs,
                                 s(:lvasgn, :foo),
                                 s(:mlhs, s(:lvasgn, :bar), s(:lvasgn, :baz))),
                               s(:send, nil, :qux))
      end

      it "works with complex destructuring of the value" do
        _("foo, (bar, baz) = [qux, [quz, quuz]]")
          .must_be_parsed_as s(:masgn,
                               s(:mlhs,
                                 s(:lvasgn, :foo),
                                 s(:mlhs, s(:lvasgn, :bar), s(:lvasgn, :baz))),
                               s(:array,
                                 s(:send, nil, :qux),
                                 s(:array,
                                   s(:send, nil, :quz),
                                   s(:send, nil, :quuz))))
      end

      it "works with destructuring with multiple levels" do
        _("((foo, bar)) = baz")
          .must_be_parsed_as s(:masgn,
                               s(:mlhs,
                                 s(:lvasgn, :foo),
                                 s(:lvasgn, :bar)),
                               s(:send, nil, :baz))
      end

      it "works with instance variables" do
        _("@foo, @bar = baz")
          .must_be_parsed_as s(:masgn,
                               s(:mlhs, s(:ivasgn, :@foo), s(:ivasgn, :@bar)),
                               s(:send, nil, :baz))
      end

      it "works with class variables" do
        _("@@foo, @@bar = baz")
          .must_be_parsed_as s(:masgn,
                               s(:mlhs, s(:cvasgn, :@@foo), s(:cvasgn, :@@bar)),
                               s(:send, nil, :baz))
      end

      it "works with attributes" do
        _("foo.bar, foo.baz = qux")
          .must_be_parsed_as s(:masgn,
                               s(:mlhs,
                                 s(:send, s(:send, nil, :foo), :bar=),
                                 s(:send, s(:send, nil, :foo), :baz=)),
                               s(:send, nil, :qux))
      end

      it "works with collection elements" do
        _("foo[1], bar[2] = baz")
          .must_be_parsed_as s(:masgn,
                               s(:mlhs,
                                 s(:indexasgn,
                                   s(:send, nil, :foo), s(:int, 1)),
                                 s(:indexasgn,
                                   s(:send, nil, :bar), s(:int, 2))),
                               s(:send, nil, :baz))
      end

      it "works with constants" do
        _("Foo, Bar = baz")
          .must_be_parsed_as s(:masgn,
                               s(:mlhs, s(:casgn, nil, :Foo), s(:casgn, nil, :Bar)),
                               s(:send, nil, :baz))
      end

      it "works with instance variables and splat" do
        _("@foo, *@bar = baz")
          .must_be_parsed_as s(:masgn,
                               s(:mlhs,
                                 s(:ivasgn, :@foo),
                                 s(:splat, s(:ivasgn, :@bar))),
                               s(:send, nil, :baz))
      end

      it "works with a right-hand single splat" do
        _("foo, bar = *baz")
          .must_be_parsed_as s(:masgn,
                               s(:mlhs, s(:lvasgn, :foo), s(:lvasgn, :bar)),
                               s(:array,
                                 s(:splat, s(:send, nil, :baz))))
      end

      it "works with a splat in a list of values on the right hand" do
        _("foo, bar = baz, *qux")
          .must_be_parsed_as s(:masgn,
                               s(:mlhs, s(:lvasgn, :foo), s(:lvasgn, :bar)),
                               s(:array,
                                 s(:send, nil, :baz),
                                 s(:splat, s(:send, nil, :qux))))
      end

      it "works with a right-hand single splat with begin..end block" do
        _("foo, bar = *begin; baz; end")
          .must_be_parsed_as s(:masgn,
                               s(:mlhs, s(:lvasgn, :foo), s(:lvasgn, :bar)),
                               s(:array,
                                 s(:splat,
                                   s(:kwbegin,
                                     s(:send, nil, :baz)))))
      end

      it "sets the correct line numbers" do
        _("foo, bar = {}, {}")
          .must_be_parsed_as s(:masgn,
                               s(:mlhs,
                                 s(:lvasgn, :foo).line(1),
                                 s(:lvasgn, :bar).line(1)).line(1),
                               s(:array,
                                 s(:hash).line(1),
                                 s(:hash).line(1)).line(1)).line(1),
                             with_line_numbers: true
      end
    end

    describe "for assignment to a collection element" do
      it "handles multiple indices" do
        _("foo[bar, baz] = qux")
          .must_be_parsed_as s(:indexasgn,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar),
                               s(:send, nil, :baz),
                               s(:send, nil, :qux))
      end

      it "handles safe-assigning to an attribute of the collection element" do
        _("foo[bar]&.baz = qux")
          .must_be_parsed_as s(:csend,
                               s(:index,
                                 s(:send, nil, :foo),
                                 s(:send, nil, :bar)),
                               :baz=,
                               s(:send, nil, :qux))
      end
    end

    describe "for operator assignment" do
      it "works with +=" do
        _("foo += bar")
          .must_be_parsed_as s(:op_asgn,
                               s(:lvasgn, :foo),
                               :+,
                               s(:send, nil, :bar))
      end

      it "works with -=" do
        _("foo -= bar")
          .must_be_parsed_as s(:op_asgn,
                               s(:lvasgn, :foo),
                               :-,
                               s(:send, nil, :bar))
      end

      it "works with *=" do
        _("foo *= bar")
          .must_be_parsed_as s(:op_asgn,
                               s(:lvasgn, :foo),
                               :*,
                               s(:send, nil, :bar))
      end

      it "works with /=" do
        _("foo /= bar")
          .must_be_parsed_as s(:op_asgn,
                               s(:lvasgn, :foo),
                               :/,
                               s(:send, nil, :bar))
      end

      it "works with ||=" do
        _("foo ||= bar")
          .must_be_parsed_as s(:or_asgn,
                               s(:lvasgn, :foo),
                               s(:send, nil, :bar))
      end

      it "works when assigning to an instance variable" do
        _("@foo += bar")
          .must_be_parsed_as s(:op_asgn,
                               s(:ivasgn, :@foo),
                               :+,
                               s(:send, nil, :bar))
      end

      it "works with boolean operators" do
        _("foo &&= bar")
          .must_be_parsed_as s(:and_asgn,
                               s(:lvasgn, :foo),
                               s(:send, nil, :bar))
      end

      it "works with boolean operators and blocks" do
        _("foo &&= begin; bar; end")
          .must_be_parsed_as s(:and_asgn,
                               s(:lvasgn, :foo),
                               s(:kwbegin,
                                 s(:send, nil, :bar)))
      end

      it "works with arithmetic operators and blocks" do
        _("foo += begin; bar; end")
          .must_be_parsed_as s(:op_asgn,
                               s(:lvasgn, :foo), :+,
                               s(:kwbegin,
                                 s(:send, nil, :bar)))
      end
    end

    describe "for operator assignment to an attribute" do
      it "works with +=" do
        _("foo.bar += baz")
          .must_be_parsed_as s(:op_asgn,
                               s(:send, s(:send, nil, :foo), :bar),
                               :+,
                               s(:send, nil, :baz))
      end

      it "works with ||=" do
        _("foo.bar ||= baz")
          .must_be_parsed_as s(:or_asgn,
                               s(:send, s(:send, nil, :foo), :bar),
                               s(:send, nil, :baz))
      end
    end

    describe "for operator assignment to a collection element" do
      it "works with +=" do
        _("foo[bar] += baz")
          .must_be_parsed_as s(:op_asgn,
                               s(:indexasgn, s(:send, nil, :foo), s(:send, nil, :bar)),
                               :+,
                               s(:send, nil, :baz))
      end

      it "works with ||=" do
        _("foo[bar] ||= baz")
          .must_be_parsed_as s(:or_asgn,
                               s(:indexasgn, s(:send, nil, :foo), s(:send, nil, :bar)),
                               s(:send, nil, :baz))
      end

      it "handles multiple indices" do
        _("foo[bar, baz] += qux")
          .must_be_parsed_as s(:op_asgn,
                               s(:indexasgn,
                                 s(:send, nil, :foo),
                                 s(:send, nil, :bar),
                                 s(:send, nil, :baz)),
                               :+,
                               s(:send, nil, :qux))
      end

      it "works with a function call without parentheses" do
        _("foo[bar] += baz qux")
          .must_be_parsed_as s(:op_asgn,
                               s(:indexasgn,
                                 s(:send, nil, :foo),
                                 s(:send, nil, :bar)),
                               :+,
                               s(:send, nil, :baz, s(:send, nil, :qux)))
      end

      it "works with a function call with parentheses" do
        _("foo[bar] += baz(qux)")
          .must_be_parsed_as s(:op_asgn,
                               s(:indexasgn,
                                 s(:send, nil, :foo),
                                 s(:send, nil, :bar)),
                               :+,
                               s(:send, nil, :baz, s(:send, nil, :qux)))
      end

      it "works with a method call without parentheses" do
        _("foo[bar] += baz.qux quuz")
          .must_be_parsed_as s(:op_asgn,
                               s(:indexasgn,
                                 s(:send, nil, :foo),
                                 s(:send, nil, :bar)),
                               :+,
                               s(:send, s(:send, nil, :baz), :qux, s(:send, nil, :quuz)))
      end

      it "works with a method call with parentheses" do
        _("foo[bar] += baz.qux(quuz)")
          .must_be_parsed_as s(:op_asgn,
                               s(:indexasgn,
                                 s(:send, nil, :foo),
                                 s(:send, nil, :bar)),
                               :+,
                               s(:send, s(:send, nil, :baz), :qux, s(:send, nil, :quuz)))
      end
    end
  end
end
