# frozen_string_literal: true

require File.expand_path("../../test_helper.rb", File.dirname(__FILE__))

describe RipperParser::Parser do
  describe "#parse" do
    describe "for character literals" do
      it "works for simple character literals" do
        _("?a")
          .must_be_parsed_as s(:str, "a")
      end

      it "works for escaped character literals" do
        _("?\\n")
          .must_be_parsed_as s(:str, "\n")
      end

      it "works for escaped character literals with ctrl" do
        _("?\\C-a")
          .must_be_parsed_as s(:str, "\u0001")
      end

      it "works for escaped character literals with meta" do
        _("?\\M-a")
          .must_be_parsed_as s(:str, [0xE1].pack("c"))
      end

      it "works for escaped character literals with meta plus shorthand ctrl" do
        _("?\\M-\\ca")
          .must_be_parsed_as s(:str, [0x81].pack("c"))
      end

      it "works for escaped character literals with shorthand ctrl plus meta" do
        _("?\\c\\M-a")
          .must_be_parsed_as s(:str, [0x81].pack("c"))
      end

      it "works for escaped character literals with meta plus ctrl" do
        _("?\\M-\\C-a")
          .must_be_parsed_as s(:str, [0x81].pack("c"))
      end

      it "works for escaped character literals with ctrl plus meta" do
        _("?\\C-\\M-a")
          .must_be_parsed_as s(:str, [0x81].pack("c"))
      end
    end

    describe "for array literals" do
      it "works for an empty array" do
        _("[]")
          .must_be_parsed_as s(:array)
      end

      it "works for a simple case with splat" do
        _("[*foo]")
          .must_be_parsed_as s(:array,
                               s(:splat, s(:send, nil, :foo)))
      end

      it "works for a multi-element case with splat" do
        _("[foo, *bar]")
          .must_be_parsed_as s(:array,
                               s(:send, nil, :foo),
                               s(:splat, s(:send, nil, :bar)))
      end
    end

    describe "for hash literals" do
      it "works for an empty hash" do
        _("{}")
          .must_be_parsed_as s(:hash)
      end

      it "works for a hash with one pair" do
        _("{foo => bar}")
          .must_be_parsed_as s(:hash,
                               s(:pair,
                                 s(:send, nil, :foo),
                                 s(:send, nil, :bar)))
      end

      it "works for a hash with multiple pairs" do
        _("{foo => bar, baz => qux}")
          .must_be_parsed_as s(:hash,
                               s(:pair,
                                 s(:send, nil, :foo),
                                 s(:send, nil, :bar)),
                               s(:pair,
                                 s(:send, nil, :baz),
                                 s(:send, nil, :qux)))
      end

      it "works for a hash with label keys" do
        _("{foo: bar, baz: qux}")
          .must_be_parsed_as s(:hash,
                               s(:pair,
                                 s(:sym, :foo),
                                 s(:send, nil, :bar)),
                               s(:pair,
                                 s(:sym, :baz),
                                 s(:send, nil, :qux)))
      end

      it "works for a hash with dynamic label keys" do
        _("{'foo': bar}")
          .must_be_parsed_as s(:hash,
                               s(:pair,
                                 s(:sym, :foo),
                                 s(:send, nil, :bar)))
      end

      it "works for a hash with splat" do
        _("{foo: bar, baz: qux, **quux}")
          .must_be_parsed_as s(:hash,
                               s(:pair, s(:sym, :foo), s(:send, nil, :bar)),
                               s(:pair, s(:sym, :baz), s(:send, nil, :qux)),
                               s(:kwsplat, s(:send, nil, :quux)))
      end

      it "works for shorthand hash syntax" do
        _("{ foo: }")
          .must_be_parsed_as s(:hash, s(:pair, s(:sym, :foo), s(:lvar, :foo)))
      end
    end

    describe "for number literals" do
      it "works for floats" do
        _("3.14")
          .must_be_parsed_as s(:float, 3.14)
      end

      it "works for octal integer literals" do
        _("0700")
          .must_be_parsed_as s(:int, 448)
      end

      it "handles negative sign for integers" do
        _("-1")
          .must_be_parsed_as s(:int, -1)
      end

      it "handles space after negative sign for integers" do
        _("-1 ")
          .must_be_parsed_as s(:int, -1)
      end

      it "handles negative sign for floats" do
        _("-3.14")
          .must_be_parsed_as s(:float, -3.14)
      end

      it "handles space after negative sign for floats" do
        _("-3.14 ")
          .must_be_parsed_as s(:float, -3.14)
      end

      it "handles positive sign" do
        _("+1")
          .must_be_parsed_as s(:int, 1)
      end

      it "works for rationals" do
        _("1000r")
          .must_be_parsed_as s(:rational, 1000r)
      end

      it "handles negative sign for rationals" do
        _("-1r")
          .must_be_parsed_as s(:rational, -1r)
      end

      it "handles positive sign for rationals" do
        _("+1r")
          .must_be_parsed_as s(:rational, 1r)
      end

      it "works for negative rational numbers with earlier spaces" do
        _("foo bar(1), baz(-1r)")
          .must_be_parsed_as s(:send, nil, :foo,
                               s(:send, nil, :bar, s(:int, 1)),
                               s(:send, nil, :baz, s(:rational, -1r)))
      end

      it "works for imaginary numbers" do
        _("1i")
          .must_be_parsed_as s(:complex, 1i)
      end

      it "handles negative sign for imaginary numbers" do
        _("-1i")
          .must_be_parsed_as s(:complex, -1i)
      end

      it "works for negative imaginary numbers with earlier spaces" do
        _("foo bar(1), baz(-1i)")
          .must_be_parsed_as s(:send, nil, :foo,
                               s(:send, nil, :bar, s(:int, 1)),
                               s(:send, nil, :baz, s(:complex, -1i)))
      end
    end
  end
end
