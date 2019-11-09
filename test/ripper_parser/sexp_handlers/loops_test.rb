# frozen_string_literal: true

require File.expand_path("../../test_helper.rb", File.dirname(__FILE__))

describe RipperParser::Parser do
  describe "#parse" do
    describe "for the while statement" do
      it "works with do" do
        _("while foo do; bar; end")
          .must_be_parsed_as s(:while,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar))
      end

      it "works without do" do
        _("while foo; bar; end")
          .must_be_parsed_as s(:while,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar))
      end

      it "works in the single-line postfix case" do
        _("foo while bar")
          .must_be_parsed_as s(:while,
                               s(:send, nil, :bar),
                               s(:send, nil, :foo))
      end

      it "works in the block postfix case" do
        _("begin; foo; end while bar")
          .must_be_parsed_as s(:while_post,
                               s(:send, nil, :bar),
                               s(:kwbegin, s(:send, nil, :foo)))
      end

      it "handles a negative condition" do
        _("while not foo; bar; end")
          .must_be_parsed_as s(:while,
                               s(:send, s(:send, nil, :foo), :!),
                               s(:send, nil, :bar))
      end

      it "handles a negative condition in the postfix case" do
        _("foo while not bar")
          .must_be_parsed_as s(:while,
                               s(:send, s(:send, nil, :bar), :!),
                               s(:send, nil, :foo))
      end

      it "handles a negated match condition" do
        _("while foo !~ bar; baz; end")
          .must_be_parsed_as s(:while,
                               s(:send, s(:send, nil, :foo), :!~, s(:send, nil, :bar)),
                               s(:send, nil, :baz))
      end

      it "handles a negated match condition in the postfix case" do
        _("baz while foo !~ bar")
          .must_be_parsed_as s(:while,
                               s(:send, s(:send, nil, :foo), :!~, s(:send, nil, :bar)),
                               s(:send, nil, :baz))
      end

      it "works with begin..end block in condition" do
        _("while begin foo end; bar; end")
          .must_be_parsed_as s(:while,
                               s(:kwbegin,
                                 s(:send, nil, :foo)),
                               s(:send, nil, :bar))
      end

      it "works with begin..end block in condition in the postfix case" do
        _("foo while begin bar end")
          .must_be_parsed_as s(:while,
                               s(:kwbegin,
                                 s(:send, nil, :bar)),
                               s(:send, nil, :foo))
      end
    end

    describe "for the until statement" do
      it "works in the prefix block case with do" do
        _("until foo do; bar; end")
          .must_be_parsed_as s(:until,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar))
      end

      it "works in the prefix block case without do" do
        _("until foo; bar; end")
          .must_be_parsed_as s(:until,
                               s(:send, nil, :foo),
                               s(:send, nil, :bar))
      end

      it "works in the single-line postfix case" do
        _("foo until bar")
          .must_be_parsed_as s(:until,
                               s(:send, nil, :bar),
                               s(:send, nil, :foo))
      end

      it "works in the block postfix case" do
        _("begin; foo; end until bar")
          .must_be_parsed_as s(:until_post,
                               s(:send, nil, :bar),
                               s(:kwbegin, s(:send, nil, :foo)))
      end

      it "handles a negative condition" do
        _("until not foo; bar; end")
          .must_be_parsed_as s(:until,
                               s(:send, s(:send, nil, :foo), :!),
                               s(:send, nil, :bar))
      end

      it "handles a negative condition in the postfix case" do
        _("foo until not bar")
          .must_be_parsed_as s(:until,
                               s(:send, s(:send, nil, :bar), :!),
                               s(:send, nil, :foo))
      end

      it "handles a negated match condition" do
        _("until foo !~ bar; baz; end")
          .must_be_parsed_as s(:until,
                               s(:send, s(:send, nil, :foo), :!~, s(:send, nil, :bar)),
                               s(:send, nil, :baz))
      end

      it "handles a negated match condition in the postfix case" do
        _("baz until foo !~ bar")
          .must_be_parsed_as s(:until,
                               s(:send, s(:send, nil, :foo), :!~, s(:send, nil, :bar)),
                               s(:send, nil, :baz))
      end

      it "cleans up begin..end block in condition" do
        _("until begin foo end; bar; end")
          .must_be_parsed_as s(:until,
                               s(:kwbegin, s(:send, nil, :foo)),
                               s(:send, nil, :bar))
      end

      it "cleans up begin..end block in condition in the postfix case" do
        _("foo until begin bar end")
          .must_be_parsed_as s(:until,
                               s(:kwbegin, s(:send, nil, :bar)),
                               s(:send, nil, :foo))
      end
    end

    describe "for the for statement" do
      it "works with do" do
        _("for foo in bar do; baz; end")
          .must_be_parsed_as s(:for,
                               s(:lvasgn, :foo),
                               s(:send, nil, :bar),
                               s(:send, nil, :baz))
      end

      it "works without do" do
        _("for foo in bar; baz; end")
          .must_be_parsed_as s(:for,
                               s(:lvasgn, :foo),
                               s(:send, nil, :bar),
                               s(:send, nil, :baz))
      end

      it "works with an empty body" do
        _("for foo in bar; end")
          .must_be_parsed_as s(:for,
                               s(:lvasgn, :foo),
                               s(:send, nil, :bar), nil)
      end

      it "works with explicit multiple assignment" do
        _("for foo, bar in baz; end")
          .must_be_parsed_as s(:for,
                               s(:mlhs,
                                 s(:lvasgn, :foo),
                                 s(:lvasgn, :bar)),
                               s(:send, nil, :baz),
                               nil)
      end

      it "works with multiple assignment with trailing comma" do
        _("for foo, in bar; end")
          .must_be_parsed_as s(:for,
                               s(:mlhs,
                                 s(:lvasgn, :foo)),
                               s(:send, nil, :bar),
                               nil)
      end
    end
  end
end
