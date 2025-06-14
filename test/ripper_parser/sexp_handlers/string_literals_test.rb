# frozen_string_literal: true

require File.expand_path("../../test_helper.rb", File.dirname(__FILE__))

describe RipperParser::Parser do
  describe "#parse" do
    describe "for regexp literals" do
      it "works for a simple regex literal" do
        _("/foo/")
          .must_be_parsed_as s(:regexp,
                               s(:str, "foo"),
                               s(:regopt))
      end

      it "works for regex literals with escaped right parenthesis" do
        _("/\\)/")
          .must_be_parsed_as s(:regexp, s(:str, "\\)"), s(:regopt))
      end

      it "works for regex literals with escape sequences" do
        _("/\\)\\n\\\\/")
          .must_be_parsed_as s(:regexp,
                               s(:str, "\\)\\n\\\\"),
                               s(:regopt))
      end

      it "works for a regex literal with the multiline flag" do
        _("/foo/m")
          .must_be_parsed_as s(:regexp, s(:str, "foo"), s(:regopt, :m))
      end

      it "works for a regex literal with the extended flag" do
        _("/foo/x")
          .must_be_parsed_as s(:regexp, s(:str, "foo"), s(:regopt, :x))
      end

      it "works for multi-line regex literals" do
        _("/foo\nbar/")
          .must_be_parsed_as s(:regexp,
                               s(:str, "foo\n"),
                               s(:str, "bar"),
                               s(:regopt))
      end

      it "works for a regex literal with the ignorecase flag" do
        _("/foo/i")
          .must_be_parsed_as s(:regexp, s(:str, "foo"), s(:regopt, :i))
      end

      it "works for a regex literal with a combination of flags" do
        _("/foo/ixm")
          .must_be_parsed_as s(:regexp, s(:str, "foo"), s(:regopt, :i, :m, :x))
      end

      it "works with the no-encoding flag" do
        _("/foo/n")
          .must_be_parsed_as s(:regexp, s(:str, "foo"), s(:regopt, :n))
      end

      it "works with line continuation" do
        _("/foo\\\nbar/")
          .must_be_parsed_as s(:regexp, s(:str, "foobar"), s(:regopt))
      end

      describe "for a %r-delimited regex literal" do
        it "works for the simple case with escape sequences" do
          _('%r[foo\nbar]')
            .must_be_parsed_as s(:regexp, s(:str, "foo\\nbar"), s(:regopt))
        end

        it "works for a multi-line regex" do
          _("%r[foo\nbar]")
            .must_be_parsed_as s(:regexp,
                                 s(:str, "foo\n"),
                                 s(:str, "bar"),
                                 s(:regopt))
        end

        it "works with odd delimiters and escape sequences" do
          _('%r_foo\nbar_')
            .must_be_parsed_as s(:regexp, s(:str, "foo\\nbar"), s(:regopt))
        end
      end

      describe "with interpolations" do
        it "works for a simple interpolation" do
          _('/foo#{bar}baz/')
            .must_be_parsed_as s(:regexp,
                                 s(:str, "foo"),
                                 s(:begin, s(:send, nil, :bar)),
                                 s(:str, "baz"), s(:regopt))
        end

        it "works for a regex literal with flags and interpolation" do
          _('/foo#{bar}/ixm')
            .must_be_parsed_as s(:regexp,
                                 s(:str, "foo"),
                                 s(:begin,
                                   s(:send, nil, :bar)),
                                 s(:regopt, :i, :m, :x))
        end

        it "works with the no-encoding flag" do
          _('/foo#{bar}/n')
            .must_be_parsed_as s(:regexp,
                                 s(:str, "foo"),
                                 s(:begin,
                                   s(:send, nil, :bar)), s(:regopt, :n))
        end

        it "works with the unicode-encoding flag" do
          _('/foo#{bar}/u')
            .must_be_parsed_as s(:regexp,
                                 s(:str, "foo"),
                                 s(:begin,
                                   s(:send, nil, :bar)), s(:regopt, :u))
        end

        it "works with unicode flag plus other flag" do
          _('/foo#{bar}/un')
            .must_be_parsed_as s(:regexp,
                                 s(:str, "foo"),
                                 s(:begin,
                                   s(:send, nil, :bar)), s(:regopt, :n, :u))
        end

        it "works with the euc-encoding flag" do
          _('/foo#{bar}/e')
            .must_be_parsed_as s(:regexp,
                                 s(:str, "foo"),
                                 s(:begin,
                                   s(:send, nil, :bar)), s(:regopt, :e))
        end

        it "works with the sjis-encoding flag" do
          _('/foo#{bar}/s')
            .must_be_parsed_as s(:regexp,
                                 s(:str, "foo"),
                                 s(:begin,
                                   s(:send, nil, :bar)), s(:regopt, :s))
        end

        it "works for a regex literal with interpolate-once flag" do
          _('/foo#{bar}/o')
            .must_be_parsed_as s(:regexp,
                                 s(:str, "foo"),
                                 s(:begin, s(:send, nil, :bar)),
                                 s(:regopt, :o))
        end

        it "works with an empty interpolation" do
          _('/foo#{}bar/')
            .must_be_parsed_as s(:regexp,
                                 s(:str, "foo"),
                                 s(:begin),
                                 s(:str, "bar"),
                                 s(:regopt))
        end

        describe "containing just a literal string" do
          it "performs no interpolation when it is at the end" do
            _('/foo#{"bar"}/')
              .must_be_parsed_as s(:regexp,
                                   s(:str, "foo"),
                                   s(:begin, s(:str, "bar")),
                                   s(:regopt))
          end

          it "performs no interpolation when it is in the middle" do
            _('/foo#{"bar"}baz/')
              .must_be_parsed_as s(:regexp,
                                   s(:str, "foo"),
                                   s(:begin, s(:str, "bar")),
                                   s(:str, "baz"),
                                   s(:regopt))
          end

          it "performs no interpolation when it is at the start" do
            _('/#{"foo"}bar/')
              .must_be_parsed_as s(:regexp,
                                   s(:begin, s(:str, "foo")),
                                   s(:str, "bar"),
                                   s(:regopt))
          end
        end
      end
    end

    describe "for string literals" do
      it "works for empty strings" do
        _("''")
          .must_be_parsed_as s(:str, "")
      end

      it "sets the encoding for literal strings to utf8 even if ascii would do" do
        parser = RipperParser::Parser.new
        result = parser.parse '"foo"'

        _(result).must_equal s(:str, "foo")
        _(result[1].encoding.to_s).must_equal "UTF-8"
      end

      it "handles line breaks within double-quoted strings" do
        _("\"foo\nbar\"")
          .must_be_parsed_as s(:dstr,
                               s(:str, "foo\n"),
                               s(:str, "bar"))
      end

      it "handles line continuation with double-quoted strings" do
        _("\"foo\\\nbar\"")
          .must_be_parsed_as s(:str, "foobar")
      end

      it "escapes line continuation with double-quoted strings" do
        _("\"foo\\\\\nbar\"")
          .must_be_parsed_as s(:dstr,
                               s(:str, "foo\\\n"),
                               s(:str, "bar"))
      end

      it "replaces carriage return/line feed combinations with line feeds" do
        _("\"bar\r\n\"")
          .must_be_parsed_as s(:str, "bar\n")
      end

      it "keeps carriage returns without line feeds" do
        _("\"bar\rbaz\r\n\"")
          .must_be_parsed_as s(:str, "bar\rbaz\n")
      end

      describe "when an encoding comment is used" do
        it "honors the encoding comment" do
          _("# encoding: ascii-8bit\n\"\\0\"")
            .must_be_parsed_as s(:str, (+"\x00").force_encoding("ASCII-8BIT"))
        end

        it "switches to UTF8 if multi-byte escapes are used" do
          _("# encoding: ascii-8bit\n\"\\u00a4\"")
            .must_be_parsed_as s(:str, "\u00a4")
        end

        it "honors the encoding comment escaped multi-byte characters" do
          _("# encoding: ascii-8bit\n'\\あ'")
            .must_be_parsed_as s(:str, (+"\\\xE3\x81\x82").force_encoding("ASCII-8bit"))
        end
      end

      describe "with double-quoted strings with escape sequences" do
        it "works for strings with escape sequences" do
          _('"\\n"')
            .must_be_parsed_as s(:str, "\n")
        end

        it "works for strings with useless escape sequences" do
          _('"F\\OO"')
            .must_be_parsed_as s(:str, "FOO")
        end

        it "works for strings with escaped backslashes" do
          _('"\\\\n"')
            .must_be_parsed_as s(:str, "\\n")
        end

        it "works for a representation of a regex literal with escaped right parenthesis" do
          _('"/\\\\)/"')
            .must_be_parsed_as s(:str, "/\\)/")
        end

        it "works for a uselessly escaped right parenthesis" do
          _('"/\\)/"')
            .must_be_parsed_as s(:str, "/)/")
        end

        it "works for a string containing escaped quotes" do
          _('"\\""')
            .must_be_parsed_as s(:str, '"')
        end

        it "works with hex escapes" do
          _('"\\x36"').must_be_parsed_as s(:str, "6")
          _('"\\x4a"').must_be_parsed_as s(:str, "J")
          _('"\\x4A"').must_be_parsed_as s(:str, "J")
          _('"\\x3Z"').must_be_parsed_as s(:str, "\x03Z")
        end

        it "works with single-letter escapes" do
          _('"foo\\abar"').must_be_parsed_as s(:str, "foo\abar")
          _('"foo\\bbar"').must_be_parsed_as s(:str, "foo\bbar")
          _('"foo\\ebar"').must_be_parsed_as s(:str, "foo\ebar")
          _('"foo\\fbar"').must_be_parsed_as s(:str, "foo\fbar")
          _('"foo\\nbar"').must_be_parsed_as s(:str, "foo\nbar")
          _('"foo\\rbar"').must_be_parsed_as s(:str, "foo\rbar")
          _('"foo\\sbar"').must_be_parsed_as s(:str, "foo\sbar")
          _('"foo\\tbar"').must_be_parsed_as s(:str, "foo\tbar")
          _('"foo\\vbar"').must_be_parsed_as s(:str, "foo\vbar")
        end

        it "works with octal number escapes" do
          _('"foo\\123bar"').must_be_parsed_as s(:str, "foo\123bar")
          _('"foo\\23bar"').must_be_parsed_as s(:str, "foo\023bar")
          _('"foo\\3bar"').must_be_parsed_as s(:str, "foo\003bar")

          _('"foo\\118bar"').must_be_parsed_as s(:str, "foo\0118bar")
          _('"foo\\18bar"').must_be_parsed_as s(:str, "foo\0018bar")
        end

        it "works with simple short hand control sequence escapes" do
          _('"foo\\cabar"').must_be_parsed_as s(:str, "foo\cabar")
          _('"foo\\cZbar"').must_be_parsed_as s(:str, "foo\cZbar")
        end

        it "works for the short hand DEL control sequence escape" do
          _('"foo\\c?bar"').must_be_parsed_as s(:str, "foo\c?bar")
        end

        it "works with simple regular control sequence escapes" do
          _('"foo\\C-abar"').must_be_parsed_as s(:str, "foo\C-abar")
          _('"foo\\C-Zbar"').must_be_parsed_as s(:str, "foo\C-Zbar")
        end

        it "works for the regular DEL control sequence escape" do
          _('"foo\\C-?bar"').must_be_parsed_as s(:str, "foo\C-?bar")
        end

        it "works with unicode escapes" do
          _('"foo\\u273bbar"').must_be_parsed_as s(:str, "foo✻bar")
        end

        it "works with unicode escapes with braces" do
          _('"foo\\u{273b}bar"').must_be_parsed_as s(:str, "foo✻bar")
        end

        it "works with unicode escapes with braces with 5 hex chars" do
          _('"foo\\u{101D1}bar"').must_be_parsed_as s(:str, "foo𐇑bar")
        end

        it "works with unicode escapes with braces with 6 hex chars" do
          _('"foo\\u{10FFFF}bar"').must_be_parsed_as s(:str, "foo\u{10FFFF}bar")
        end

        it "converts octal escapes to unicode if possible" do
          _('"2\302\275"').must_be_parsed_as s(:str, "2½")
        end

        it "converts hex escapes to unicode if possible" do
          _('"\xE6\x97\xA5\xE6\x9C\xAC\xE8\xAA\x9E"').must_be_parsed_as s(:str, "日本語")
        end

        it "raises an error if resulting string literal encoding" do
          parser = RipperParser::Parser.new

          _(proc { parser.parse '"2\x82\302\275"' }).must_raise RipperParser::SyntaxError
        end
      end

      describe "with interpolations containing just a literal string" do
        it "performs no interpolation when it is at the end" do
          _('"foo#{"bar"}"')
            .must_be_parsed_as s(:dstr,
                                 s(:str, "foo"),
                                 s(:begin, s(:str, "bar")))
        end

        it "performs no interpolation when it is in the middle" do
          _('"foo#{"bar"}baz"')
            .must_be_parsed_as s(:dstr,
                                 s(:str, "foo"),
                                 s(:begin, s(:str, "bar")),
                                 s(:str, "baz"))
        end

        it "performs no interpolation when it is at the start" do
          _('"#{"foo"}bar"')
            .must_be_parsed_as s(:dstr,
                                 s(:begin, s(:str, "foo")),
                                 s(:str, "bar"))
        end
      end

      describe "with interpolations without braces" do
        it "works for ivars" do
          _("\"foo\#@bar\"").must_be_parsed_as s(:dstr,
                                                 s(:str, "foo"),
                                                 s(:begin, s(:ivar, :@bar)))
        end

        it "works for gvars" do
          _("\"foo\#$bar\"").must_be_parsed_as s(:dstr,
                                                 s(:str, "foo"),
                                                 s(:begin, s(:gvar, :$bar)))
        end

        it "works for cvars" do
          _("\"foo\#@@bar\"").must_be_parsed_as s(:dstr,
                                                  s(:str, "foo"),
                                                  s(:begin, s(:cvar, :@@bar)))
        end
      end

      describe "with interpolations with braces" do
        it "works for trivial interpolated strings" do
          _('"#{foo}"')
            .must_be_parsed_as s(:dstr,
                                 s(:begin,
                                   s(:send, nil, :foo)))
        end

        it "works for basic interpolated strings" do
          _('"foo#{bar}"')
            .must_be_parsed_as s(:dstr,
                                 s(:str, "foo"),
                                 s(:begin,
                                   s(:send, nil, :bar)))
        end

        it "works for strings with several interpolations" do
          _('"foo#{bar}baz#{qux}"')
            .must_be_parsed_as s(:dstr,
                                 s(:str, "foo"),
                                 s(:begin, s(:send, nil, :bar)),
                                 s(:str, "baz"),
                                 s(:begin, s(:send, nil, :qux)))
        end

        it "correctly handles two interpolations in a row" do
          _("\"\#{bar}\#{qux}\"")
            .must_be_parsed_as s(:dstr,
                                 s(:begin, s(:send, nil, :bar)),
                                 s(:begin, s(:send, nil, :qux)))
        end

        it "works with an empty interpolation" do
          _("\"foo\#{}bar\"")
            .must_be_parsed_as s(:dstr,
                                 s(:str, "foo"),
                                 s(:begin),
                                 s(:str, "bar"))
        end

        it "correctly handles interpolation with __FILE__ before another interpolation" do
          _("\"foo\#{__FILE__}\#{bar}\"")
            .must_be_parsed_as s(:dstr,
                                 s(:str, "foo"),
                                 s(:begin, s(:str, "(string)")),
                                 s(:begin, s(:send, nil, :bar)))
        end

        it "correctly handles interpolation with __FILE__ after another interpolation" do
          _("\"\#{bar}foo\#{__FILE__}\"")
            .must_be_parsed_as s(:dstr,
                                 s(:begin, s(:send, nil, :bar)),
                                 s(:str, "foo"),
                                 s(:begin, s(:str, "(string)")))
        end

        it "correctly handles nested interpolation" do
          _('"foo#{"bar#{baz}"}"')
            .must_be_parsed_as s(:dstr,
                                 s(:str, "foo"),
                                 s(:begin,
                                   s(:dstr,
                                     s(:str, "bar"),
                                     s(:begin, s(:send, nil, :baz)))))
        end

        it "correctly handles consecutive nested interpolation" do
          _('"foo#{"bar#{baz}"}foo#{"bar#{baz}"}"')
            .must_be_parsed_as s(:dstr,
                                 s(:str, "foo"),
                                 s(:begin,
                                   s(:dstr,
                                     s(:str, "bar"),
                                     s(:begin, s(:send, nil, :baz)))),
                                 s(:str, "foo"),
                                 s(:begin,
                                   s(:dstr,
                                     s(:str, "bar"),
                                     s(:begin, s(:send, nil, :baz)))))
        end
      end

      describe "with interpolations and escape sequences" do
        it "works when interpolations are followed by escape sequences" do
          _('"#{foo}\\n"')
            .must_be_parsed_as s(:dstr,
                                 s(:begin, s(:send, nil, :foo)),
                                 s(:str, "\n"))
        end

        it "works when interpolations contain a mix of other string-like literals" do
          _('"#{[:foo, \'bar\']}\\n"')
            .must_be_parsed_as s(:dstr,
                                 s(:begin, s(:array, s(:sym, :foo), s(:str, "bar"))),
                                 s(:str, "\n"))
        end

        it "converts to unicode after interpolation" do
          _('"#{foo}2\302\275"')
            .must_be_parsed_as s(:dstr,
                                 s(:begin, s(:send, nil, :foo)),
                                 s(:str, "2½"))
        end

        it "convert null byte to unicode after interpolation" do
          _('"#{foo}\0"')
            .must_be_parsed_as s(:dstr,
                                 s(:begin, s(:send, nil, :foo)),
                                 s(:str, "\u0000"))
        end

        it "converts string with null to unicode after interpolation" do
          _('"#{foo}bar\0"')
            .must_be_parsed_as s(:dstr,
                                 s(:begin, s(:send, nil, :foo)),
                                 s(:str, "bar\x00"))
        end
      end

      describe "with single quoted strings" do
        it "works with escaped single quotes" do
          _("'foo\\'bar'")
            .must_be_parsed_as s(:str, "foo'bar")
        end

        it "works with embedded backslashes" do
          _("'foo\\abar'")
            .must_be_parsed_as s(:str, 'foo\abar')
        end

        it "works with escaped embedded backslashes" do
          _("'foo\\\\abar'")
            .must_be_parsed_as s(:str, 'foo\abar')
        end

        it "works with sequences of backslashes" do
          _("'foo\\\\\\abar'")
            .must_be_parsed_as s(:str, "foo\\\\abar")
        end

        it "does not process line continuation" do
          _("'foo\\\nbar'")
            .must_be_parsed_as s(:dstr,
                                 s(:str, "foo\\\n"),
                                 s(:str, "bar"))
        end
      end

      describe "with %Q-delimited strings" do
        it "works for the simple case" do
          _("%Q[bar]")
            .must_be_parsed_as s(:str, "bar")
        end

        it "works for escape sequences" do
          _("%Q[foo\\nbar]")
            .must_be_parsed_as s(:str, "foo\nbar")
        end

        it "works for multi-line strings" do
          _("%Q[foo\nbar]")
            .must_be_parsed_as s(:dstr,
                                 s(:str, "foo\n"),
                                 s(:str, "bar"))
        end

        it "handles line continuation" do
          _("%Q[foo\\\nbar]")
            .must_be_parsed_as s(:str, "foobar")
        end
      end

      describe "with %q-delimited strings" do
        it "works for the simple case" do
          _("%q[bar]")
            .must_be_parsed_as s(:str, "bar")
        end

        it "does not unescape escape sequences" do
          _("%q[foo\\nbar]")
            .must_be_parsed_as s(:str, "foo\\nbar")
        end

        it "does not unescape invalid escape sequences" do
          _("%q[foo\\ubar]")
            .must_be_parsed_as s(:str, "foo\\ubar")
        end

        it "handles escaped delimiters for brackets" do
          _("%q[foo\\[bar\\]baz]")
            .must_be_parsed_as s(:str, "foo[bar]baz")
        end

        it "handles escaped delimiters for parentheses" do
          _("%q(foo\\(bar\\)baz)")
            .must_be_parsed_as s(:str, "foo(bar)baz")
        end

        it "handles escaped delimiters for braces" do
          _("%q{foo\\{bar\\}baz}")
            .must_be_parsed_as s(:str, "foo{bar}baz")
        end

        it "handles escaped delimiters for angle brackets" do
          _("%q<foo\\<bar\\>baz>")
            .must_be_parsed_as s(:str, "foo<bar>baz")
        end

        it "handles escaped delimiters for slashes" do
          _("%q/foo\\/bar]baz/")
            .must_be_parsed_as s(:str, "foo/bar]baz")
        end

        it "does not unescape unused delimiters" do
          _("%q[foo\\{\\}\\<\\>\\(\\)baz]")
            .must_be_parsed_as s(:str, "foo\\{\\}\\<\\>\\(\\)baz")
        end

        it "does not unescape escape sequences for single quotes" do
          _("%q[foo\\'bar]")
            .must_be_parsed_as s(:str, "foo\\'bar")
        end

        it "works for multi-line strings" do
          _("%q[foo\nbar]")
            .must_be_parsed_as s(:dstr,
                                 s(:str, "foo\n"),
                                 s(:str, "bar"))
        end

        it "handles line continuation" do
          _("%q[foo\\\nbar]")
            .must_be_parsed_as s(:dstr,
                                 s(:str, "foo\\\n"),
                                 s(:str, "bar"))
        end
      end

      describe "with %-delimited strings" do
        it "works for the simple case" do
          _("%(bar)")
            .must_be_parsed_as s(:str, "bar")
        end

        it "works for escape sequences" do
          _('%(foo\nbar)')
            .must_be_parsed_as s(:str, "foo\nbar")
        end

        it "works for multiple lines" do
          _("%(foo\nbar)")
            .must_be_parsed_as s(:dstr,
                                 s(:str, "foo\n"),
                                 s(:str, "bar"))
        end

        it "works with line continuations" do
          _("%(foo\\\nbar)")
            .must_be_parsed_as s(:str, "foobar")
        end

        it "works for odd delimiters" do
          _('%!foo\nbar!')
            .must_be_parsed_as s(:str, "foo\nbar")
        end
      end

      describe "with string concatenation" do
        it "makes a :dstr in the case of two simple literal strings" do
          _('"foo" "bar"').must_be_parsed_as s(:dstr,
                                               s(:str, "foo"),
                                               s(:str, "bar"))
        end

        it "makes a :dstr when the right string has interpolations" do
          _("\"foo\" \"bar\#{baz}\"")
            .must_be_parsed_as s(:dstr,
                                 s(:str, "foo"),
                                 s(:dstr,
                                   s(:str, "bar"),
                                   s(:begin, s(:send, nil, :baz))))
        end

        describe "when the left string has interpolations" do
          it "makes a :dstr" do
            _("\"foo\#{bar}\" \"baz\"")
              .must_be_parsed_as s(:dstr,
                                   s(:dstr,
                                     s(:str, "foo"),
                                     s(:begin, s(:send, nil, :bar))),
                                   s(:str, "baz"))
          end

          it "makes a :dstr with an empty string" do
            _("\"foo\#{bar}\" \"\"")
              .must_be_parsed_as s(:dstr,
                                   s(:dstr,
                                     s(:str, "foo"),
                                     s(:begin, s(:send, nil, :bar))),
                                   s(:str, ""))
          end
        end

        describe "when both strings have interpolations" do
          it "makes a :dstr" do
            _("\"foo\#{bar}\" \"baz\#{qux}\"")
              .must_be_parsed_as s(:dstr,
                                   s(:dstr,
                                     s(:str, "foo"),
                                     s(:begin, s(:send, nil, :bar))),
                                   s(:dstr,
                                     s(:str, "baz"),
                                     s(:begin, s(:send, nil, :qux))))
          end

          it "removes empty substrings from the concatenation" do
            _("\"foo\#{bar}\" \"\#{qux}\"")
              .must_be_parsed_as s(:dstr,
                                   s(:dstr,
                                     s(:str, "foo"),
                                     s(:begin, s(:send, nil, :bar))),
                                   s(:dstr,
                                     s(:begin, s(:send, nil, :qux))))
          end
        end
      end

      describe "for heredocs" do
        it "works for the simple case" do
          _("<<FOO\nbar\nFOO")
            .must_be_parsed_as s(:str, "bar\n")
        end

        it "works with multiple lines" do
          _("<<FOO\nbar\nbaz\nFOO")
            .must_be_parsed_as s(:dstr,
                                 s(:str, "bar\n"),
                                 s(:str, "baz\n"))
        end

        it "works for escape sequences" do
          _("<<FOO\nbar\\tbaz\nFOO")
            .must_be_parsed_as s(:str, "bar\tbaz\n")
        end

        it 'converts \r to carriage returns' do
          _("<<FOO\nbar\\rbaz\\r\nFOO")
            .must_be_parsed_as s(:str, "bar\rbaz\r\n")
        end

        it "replaces carriage return/line feed combinations with line feeds" do
          _("<<FOO\nbar\r\nFOO")
            .must_be_parsed_as s(:str, "bar\n")
        end

        it "keeps carriage returns without line feeds" do
          _("<<FOO\nbar\rbaz\r\nFOO")
            .must_be_parsed_as s(:str, "bar\rbaz\n")
        end

        it "does not unescape with single quoted version" do
          _("<<'FOO'\nbar\\tbaz\nFOO")
            .must_be_parsed_as s(:str, "bar\\tbaz\n")
        end

        it "works with multiple lines with the single quoted version" do
          _("<<'FOO'\nbar\nbaz\nFOO")
            .must_be_parsed_as s(:dstr,
                                 s(:str, "bar\n"),
                                 s(:str, "baz\n"))
        end

        it "handles line continuation" do
          _("<<FOO\nbar\\\nbaz\nFOO")
            .must_be_parsed_as s(:str, "barbaz\n")
        end

        it "ignores line continuation for the single quoted version" do
          _("<<'FOO'\nbar \\\nbaz\nFOO")
            .must_be_parsed_as s(:dstr, s(:str, "bar \\\n"), s(:str, "baz\n"))
        end

        it "escapes line continuation" do
          _("<<FOO\nbar\\\\\nbaz\nFOO")
            .must_be_parsed_as s(:dstr,
                                 s(:str, "bar\\\n"),
                                 s(:str, "baz\n"))
        end

        it "converts to unicode" do
          _("<<FOO\n2\\302\\275\nFOO")
            .must_be_parsed_as s(:str, "2½\n")
        end

        it "handles interpolation" do
          _("<<FOO\n\#{bar}\nFOO")
            .must_be_parsed_as s(:dstr,
                                 s(:begin, s(:send, nil, :bar)),
                                 s(:str, "\n"))
        end

        it "handles interpolation with subsequent whitespace" do
          _("<<FOO\n\#{bar} baz\nFOO")
            .must_be_parsed_as s(:dstr,
                                 s(:begin, s(:send, nil, :bar)),
                                 s(:str, " baz\n"))
        end

        it "handles line continuation after interpolation" do
          _("<<FOO\n\#{bar}\nbaz\\\nqux\nFOO")
            .must_be_parsed_as s(:dstr,
                                 s(:begin, s(:send, nil, :bar)),
                                 s(:str, "\n"),
                                 s(:str, "bazqux\n"))
        end
      end

      describe "for the indentable case" do
        it "works for the indentable case" do
          _("<<-FOO\n  bar\n  FOO")
            .must_be_parsed_as s(:str, "  bar\n")
        end

        it "does not unescape with indentable single quoted version" do
          _("<<-'FOO'\n  bar\\tbaz\n  FOO")
            .must_be_parsed_as s(:str, "  bar\\tbaz\n")
        end

        it "handles line continuation after interpolation for the indentable case" do
          _("<<-FOO\n\#{bar}\nbaz\\\nqux\nFOO")
            .must_be_parsed_as s(:dstr,
                                 s(:begin, s(:send, nil, :bar)),
                                 s(:str, "\n"),
                                 s(:str, "bazqux\n"))
        end
      end

      describe "for squiggly heredocs" do
        it "works for the simple case" do
          _("  <<~FOO\n  bar\n  FOO")
            .must_be_parsed_as s(:str, "bar\n")
        end

        it "does not unescape the single quoted version" do
          _("<<~'FOO'\n  bar\\tbaz\n  FOO")
            .must_be_parsed_as s(:str, "bar\\tbaz\n")
        end

        it "ignores line continuation for the single quoted version" do
          _("<<~'FOO'\n  bar \\\n  baz\nFOO")
            .must_be_parsed_as s(:dstr, s(:str, "bar \\\n"), s(:str, "baz\n"))
        end

        it "handles interpolation as the first part" do
          _("<<~FOO\n  \#{bar}\nFOO")
            .must_be_parsed_as s(:dstr,
                                 s(:begin,
                                   s(:send, nil, :bar)),
                                 s(:str, "\n"))
        end

        it "handles interpolation after a literal part" do
          _("<<~FOO\n  foo\n  \#{bar}\nFOO")
            .must_be_parsed_as s(:dstr,
                                 s(:str, "foo\n"),
                                 s(:begin,
                                   s(:send, nil, :bar)),
                                 s(:str, "\n"))
        end

        it "handles interpolation with subsequent whitespace" do
          _("<<~FOO\n  \#{bar} baz\nFOO")
            .must_be_parsed_as s(:dstr,
                                 s(:begin,
                                   s(:send, nil, :bar)),
                                 s(:str, " baz\n"))
        end
      end
    end

    describe "for word list literals with %w delimiter" do
      it "works for the simple case" do
        _("%w(foo bar)")
          .must_be_parsed_as s(:array, s(:str, "foo"), s(:str, "bar"))
      end

      it "does not perform interpolation" do
        _("%w(foo\\nbar baz)")
          .must_be_parsed_as s(:array, s(:str, "foo\\nbar"), s(:str, "baz"))
      end

      it "handles line continuation" do
        _("%w(foo\\\nbar baz)")
          .must_be_parsed_as s(:array, s(:str, "foo\nbar"), s(:str, "baz"))
      end

      it "handles escaped spaces" do
        _("%w(foo bar\\ baz)")
          .must_be_parsed_as s(:array, s(:str, "foo"), s(:str, "bar baz"))
      end

      it "handles escaped delimiters for brackets" do
        _("%w[foo \\[bar\\] baz]")
          .must_be_parsed_as s(:array, s(:str, "foo"), s(:str, "[bar]"), s(:str, "baz"))
      end

      it "handles escaped delimiters for parentheses" do
        _("%w(foo\\(bar\\)baz)")
          .must_be_parsed_as s(:array, s(:str, "foo(bar)baz"))
      end

      it "handles escaped delimiters for braces" do
        _("%w{foo\\{bar\\}baz}")
          .must_be_parsed_as s(:array, s(:str, "foo{bar}baz"))
      end

      it "handles escaped delimiters for angle brackets" do
        _("%w<foo\\<bar\\>baz>")
          .must_be_parsed_as s(:array, s(:str, "foo<bar>baz"))
      end

      it "handles escaped delimiters for slashes" do
        _("%w/foo\\/bar]baz/")
          .must_be_parsed_as s(:array, s(:str, "foo/bar]baz"))
      end

      it "does not unescape unused delimiters" do
        _("%w[foo\\{\\}\\<\\>\\(\\)baz]")
          .must_be_parsed_as s(:array, s(:str, "foo\\{\\}\\<\\>\\(\\)baz"))
      end

      it "does not unescape escape sequences for single quotes" do
        _("%w[foo\\'bar]")
          .must_be_parsed_as s(:array, s(:str, "foo\\'bar"))
      end
    end

    describe "for word list literals with %W delimiter" do
      it "works for the simple case" do
        _("%W(foo bar)")
          .must_be_parsed_as s(:array, s(:str, "foo"), s(:str, "bar"))
      end

      it "handles escaped spaces" do
        _("%W(foo bar\\ baz)")
          .must_be_parsed_as s(:array, s(:str, "foo"), s(:str, "bar baz"))
      end

      it "correctly handles interpolation" do
        _("%W(foo \#{bar} baz)")
          .must_be_parsed_as  s(:array,
                                s(:str, "foo"),
                                s(:dstr, s(:begin, s(:send, nil, :bar))),
                                s(:str, "baz"))
      end

      it "correctly handles braceless interpolation" do
        _("%W(foo \#@bar baz)")
          .must_be_parsed_as  s(:array,
                                s(:str, "foo"),
                                s(:dstr, s(:begin, s(:ivar, :@bar))),
                                s(:str, "baz"))
      end

      it "correctly handles in-word interpolation" do
        _("%W(foo \#{bar}baz)")
          .must_be_parsed_as s(:array,
                               s(:str, "foo"),
                               s(:dstr,
                                 s(:begin, s(:send, nil, :bar)),
                                 s(:str, "baz")))
      end

      it "correctly handles escape sequences" do
        _('%W(foo\nbar baz)')
          .must_be_parsed_as s(:array,
                               s(:str, "foo\nbar"),
                               s(:str, "baz"))
      end

      it "converts to unicode if possible" do
        _('%W(2\302\275)').must_be_parsed_as s(:array, s(:str, "2½"))
      end

      it "correctly handles line continuation" do
        _("%W(foo\\\nbar baz)")
          .must_be_parsed_as s(:array,
                               s(:str, "foo\nbar"),
                               s(:str, "baz"))
      end

      it "correctly handles multiple lines" do
        _("%W(foo\nbar baz)")
          .must_be_parsed_as s(:array,
                               s(:str, "foo"),
                               s(:str, "bar"),
                               s(:str, "baz"))
      end
    end

    describe "for symbol list literals with %i delimiter" do
      it "works for the simple case" do
        _("%i(foo bar)")
          .must_be_parsed_as s(:array, s(:sym, :foo), s(:sym, :bar))
      end

      it "does not perform interpolation" do
        _("%i(foo\\nbar baz)")
          .must_be_parsed_as s(:array, s(:sym, :"foo\\nbar"), s(:sym, :baz))
      end

      it "handles line continuation" do
        _("%i(foo\\\nbar baz)")
          .must_be_parsed_as s(:array, s(:sym, :"foo\nbar"), s(:sym, :baz))
      end
    end

    describe "for symbol list literals with %I delimiter" do
      it "works for the simple case" do
        _("%I(foo bar)")
          .must_be_parsed_as s(:array, s(:sym, :foo), s(:sym, :bar))
      end

      it "correctly handles escape sequences" do
        _('%I(foo\nbar baz)')
          .must_be_parsed_as s(:array,
                               s(:sym, :"foo\nbar"),
                               s(:sym, :baz))
      end

      it "correctly handles interpolation" do
        _("%I(foo \#{bar} baz)")
          .must_be_parsed_as s(:array,
                               s(:sym, :foo),
                               s(:dsym, s(:begin, s(:send, nil, :bar))),
                               s(:sym, :baz))
      end

      it "correctly handles in-word interpolation" do
        _("%I(foo \#{bar}baz)")
          .must_be_parsed_as s(:array,
                               s(:sym, :foo),
                               s(:dsym,
                                 s(:begin, s(:send, nil, :bar)),
                                 s(:str, "baz")))
      end

      it "correctly handles line continuation" do
        _("%I(foo\\\nbar baz)")
          .must_be_parsed_as s(:array,
                               s(:sym, :"foo\nbar"),
                               s(:sym, :baz))
      end

      it "correctly handles multiple lines" do
        _("%I(foo\nbar baz)")
          .must_be_parsed_as s(:array,
                               s(:sym, :foo),
                               s(:sym, :bar),
                               s(:sym, :baz))
      end
    end

    describe "for symbol literals" do
      it "works for simple symbols" do
        _(":foo")
          .must_be_parsed_as s(:sym, :foo)
      end

      it "works for symbols that look like instance variable names" do
        _(":@foo")
          .must_be_parsed_as s(:sym, :@foo)
      end

      it "works for symbols that look like class names" do
        _(":Foo")
          .must_be_parsed_as s(:sym, :Foo)
      end

      it "works for symbols that look like keywords" do
        _(":class").must_be_parsed_as s(:sym, :class)
      end

      it "works for :__LINE__" do
        _(":__LINE__")
          .must_be_parsed_as s(:sym, :__LINE__)
      end

      it "works for :__FILE__" do
        _(":__FILE__")
          .must_be_parsed_as s(:sym, :__FILE__)
      end

      it "works for a backtick symbol" do
        _(":`").must_be_parsed_as s(:sym, :`)
      end

      it "works for simple dsyms" do
        _(':"foo"')
          .must_be_parsed_as s(:sym, :foo)
      end

      it "works for dsyms with interpolations" do
        _(':"foo#{bar}"')
          .must_be_parsed_as s(:dsym,
                               s(:str, "foo"),
                               s(:begin, s(:send, nil, :bar)))
      end

      it "works for dsyms with interpolations at the start" do
        _(':"#{bar}"')
          .must_be_parsed_as s(:dsym,
                               s(:begin, s(:send, nil, :bar)))
      end

      it "works for dsyms with escape sequences" do
        _(':"foo\nbar"')
          .must_be_parsed_as s(:sym, :"foo\nbar")
      end

      it "works for dsyms with multiple lines" do
        _(":\"foo\nbar\"")
          .must_be_parsed_as s(:dsym,
                               s(:str, "foo\n"),
                               s(:str, "bar"))
      end

      it "works for dsyms with line continuations" do
        _(":\"foo\\\nbar\"")
          .must_be_parsed_as s(:sym, :foobar)
      end

      it "works with single quoted dsyms" do
        _(":'foo'")
          .must_be_parsed_as s(:sym, :foo)
      end

      it "works with single quoted dsyms with escaped single quotes" do
        _(":'foo\\'bar'")
          .must_be_parsed_as s(:sym, :"foo'bar")
      end

      it "works with single quoted dsyms with multiple lines" do
        _(":'foo\nbar'")
          .must_be_parsed_as s(:dsym,
                               s(:str, "foo\n"),
                               s(:str, "bar"))
      end

      it "works with single quoted dsyms with line continuations" do
        _(":'foo\\\nbar'")
          .must_be_parsed_as s(:dsym,
                               s(:str, "foo\\\n"),
                               s(:str, "bar"))
      end

      it "works with single quoted dsyms with embedded backslashes" do
        _(":'foo\\abar'")
          .must_be_parsed_as s(:sym, :"foo\\abar")
      end

      it "works with barewords that need to be interpreted as symbols" do
        _("alias foo bar")
          .must_be_parsed_as s(:alias,
                               s(:sym, :foo), s(:sym, :bar))
      end

      it "works for empty dsyms" do
        _(':""')
          .must_be_parsed_as s(:dsym)
      end

      it "assigns a line number to the result" do
        _(":foo")
          .must_be_parsed_as s(:sym, :foo).line(1), with_line_numbers: true
      end
    end

    describe "for backtick string literals" do
      it "works for basic backtick strings" do
        _("`foo`")
          .must_be_parsed_as s(:xstr, s(:str, "foo"))
      end

      it "works for interpolated backtick strings" do
        _('`foo#{bar}`')
          .must_be_parsed_as s(:xstr,
                               s(:str, "foo"),
                               s(:begin, s(:send, nil, :bar)))
      end

      it "works for backtick strings interpolated at the start" do
        _('`#{foo}`')
          .must_be_parsed_as s(:xstr,
                               s(:begin, s(:send, nil, :foo)))
      end

      it "works for backtick strings with escape sequences" do
        _("`foo\\n`")
          .must_be_parsed_as s(:xstr, s(:str, "foo\n"))
      end

      it "works for backtick strings with multiple lines" do
        _("`foo\nbar`")
          .must_be_parsed_as s(:xstr,
                               s(:str, "foo\n"),
                               s(:str, "bar"))
      end

      it "works for backtick strings with line continuations" do
        _("`foo\\\nbar`")
          .must_be_parsed_as s(:xstr,
                               s(:str, "foobar"))
      end
    end
  end
end
