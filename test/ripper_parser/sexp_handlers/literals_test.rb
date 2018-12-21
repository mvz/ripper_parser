require File.expand_path('../../test_helper.rb', File.dirname(__FILE__))

describe RipperParser::Parser do
  describe '#parse' do
    describe 'for regexp literals' do
      it 'works for a simple regex literal' do
        '/foo/'.
          must_be_parsed_as s(:regexp,
                              s(:str, 'foo'),
                              s(:regopt))
      end

      it 'works for regex literals with escaped right parenthesis' do
        '/\\)/'.
          must_be_parsed_as s(:regexp, s(:str, '\\)'), s(:regopt))
      end

      it 'works for regex literals with escape sequences' do
        '/\\)\\n\\\\/'.
          must_be_parsed_as s(:regexp,
                              s(:str, '\\)\\n\\\\'),
                              s(:regopt))
      end

      it 'works for a regex literal with the multiline flag' do
        '/foo/m'.
          must_be_parsed_as s(:regexp, s(:str, 'foo'), s(:regopt, :m))
      end

      it 'works for a regex literal with the extended flag' do
        '/foo/x'.
          must_be_parsed_as s(:regexp, s(:str, 'foo'), s(:regopt, :x))
      end

      it 'works for a regex literal with the ignorecase flag' do
        '/foo/i'.
          must_be_parsed_as s(:regexp, s(:str, 'foo'), s(:regopt, :i))
      end

      it 'works for a regex literal with a combination of flags' do
        '/foo/ixm'.
          must_be_parsed_as s(:regexp, s(:str, 'foo'), s(:regopt, :i, :m, :x))
      end

      it 'works with the no-encoding flag' do
        '/foo/n'.
          must_be_parsed_as s(:regexp, s(:str, 'foo'), s(:regopt, :n))
      end

      it 'works with line continuation' do
        "/foo\\\nbar/".
          must_be_parsed_as s(:regexp, s(:str, 'foobar'), s(:regopt))
      end

      describe 'for a %r-delimited regex literal' do
        it 'works for the simple case with escape sequences' do
          '%r[foo\nbar]'.
            must_be_parsed_as s(:regexp, s(:str, 'foo\\nbar'), s(:regopt))
        end

        it 'works with odd delimiters and escape sequences' do
          '%r_foo\nbar_'.
            must_be_parsed_as s(:regexp, s(:str, 'foo\\nbar'), s(:regopt))
        end
      end

      describe 'with interpolations' do
        it 'works for a simple interpolation' do
          '/foo#{bar}baz/'.
            must_be_parsed_as s(:regexp,
                                s(:str, 'foo'),
                                s(:begin, s(:send, nil, :bar)),
                                s(:str, 'baz'), s(:regopt))
        end

        it 'works for a regex literal with flags and interpolation' do
          '/foo#{bar}/ixm'.
            must_be_parsed_as s(:regexp,
                                s(:str, 'foo'),
                                s(:begin,
                                  s(:send, nil, :bar)),
                                s(:regopt, :i, :m, :x))
        end

        it 'works with the no-encoding flag' do
          '/foo#{bar}/n'.
            must_be_parsed_as s(:regexp,
                                s(:str, 'foo'),
                                s(:begin,
                                  s(:send, nil, :bar)), s(:regopt, :n))
        end

        it 'works with the unicode-encoding flag' do
          '/foo#{bar}/u'.
            must_be_parsed_as s(:regexp,
                                s(:str, 'foo'),
                                s(:begin,
                                  s(:send, nil, :bar)), s(:regopt, :u))
        end

        it 'works with the euc-encoding flag' do
          '/foo#{bar}/e'.
            must_be_parsed_as s(:regexp,
                                s(:str, 'foo'),
                                s(:begin,
                                  s(:send, nil, :bar)), s(:regopt, :e))
        end

        it 'works with the sjis-encoding flag' do
          '/foo#{bar}/s'.
            must_be_parsed_as s(:regexp,
                                s(:str, 'foo'),
                                s(:begin,
                                  s(:send, nil, :bar)), s(:regopt, :s))
        end

        it 'works for a regex literal with interpolate-once flag' do
          '/foo#{bar}/o'.
            must_be_parsed_as s(:regexp,
                                s(:str, 'foo'),
                                s(:begin, s(:send, nil, :bar)),
                                s(:regopt, :o))
        end

        it 'works with an empty interpolation' do
          '/foo#{}bar/'.
            must_be_parsed_as s(:regexp,
                                s(:str, 'foo'),
                                s(:begin),
                                s(:str, 'bar'),
                                s(:regopt))
        end

        describe 'containing just a literal string' do
          it 'performs no interpolation when it is at the end' do
            '/foo#{"bar"}/'.
              must_be_parsed_as s(:regexp,
                                  s(:str, 'foo'),
                                  s(:begin, s(:str, 'bar')),
                                  s(:regopt))
          end

          it 'performs no interpolation when it is in the middle' do
            '/foo#{"bar"}baz/'.
              must_be_parsed_as s(:regexp,
                                  s(:str, 'foo'),
                                  s(:begin, s(:str, 'bar')),
                                  s(:str, 'baz'),
                                  s(:regopt))
          end

          it 'performs no interpolation when it is at the start' do
            '/#{"foo"}bar/'.
              must_be_parsed_as s(:regexp,
                                  s(:begin, s(:str, 'foo')),
                                  s(:str, 'bar'),
                                  s(:regopt))
          end
        end
      end
    end

    describe 'for string literals' do
      it 'works for empty strings' do
        "''".
          must_be_parsed_as s(:str, '')
      end

      it 'sets the encoding for literal strings to utf8 even if ascii would do' do
        parser = RipperParser::Parser.new
        result = parser.parse '"foo"'
        result.must_equal s(:str, 'foo')
        result[1].encoding.to_s.must_equal 'UTF-8'
      end

      it 'handles line continuation with double-quoted strings' do
        "\"foo\\\nbar\"".
          must_be_parsed_as s(:str, 'foobar')
      end

      it 'escapes line continuation with double-quoted strings' do
        "\"foo\\\\\nbar\"".
          must_be_parsed_as s(:str, "foo\\\nbar")
      end

      describe 'with double-quoted strings with escape sequences' do
        it 'works for strings with escape sequences' do
          '"\\n"'.
            must_be_parsed_as s(:str, "\n")
        end

        it 'works for strings with useless escape sequences' do
          '"F\\OO"'.
            must_be_parsed_as s(:str, 'FOO')
        end

        it 'works for strings with escaped backslashes' do
          '"\\\\n"'.
            must_be_parsed_as s(:str, '\\n')
        end

        it 'works for a representation of a regex literal with escaped right parenthesis' do
          '"/\\\\)/"'.
            must_be_parsed_as s(:str, '/\\)/')
        end

        it 'works for a uselessly escaped right parenthesis' do
          '"/\\)/"'.
            must_be_parsed_as s(:str, '/)/')
        end

        it 'works for a string containing escaped quotes' do
          '"\\""'.
            must_be_parsed_as s(:str, '"')
        end

        it 'works with hex escapes' do
          '"\\x36"'.must_be_parsed_as s(:str, '6')
          '"\\x4a"'.must_be_parsed_as s(:str, 'J')
          '"\\x4A"'.must_be_parsed_as s(:str, 'J')
          '"\\x3Z"'.must_be_parsed_as s(:str, "\x03Z")
        end

        it 'works with single-letter escapes' do
          '"foo\\abar"'.must_be_parsed_as s(:str, "foo\abar")
          '"foo\\bbar"'.must_be_parsed_as s(:str, "foo\bbar")
          '"foo\\ebar"'.must_be_parsed_as s(:str, "foo\ebar")
          '"foo\\fbar"'.must_be_parsed_as s(:str, "foo\fbar")
          '"foo\\nbar"'.must_be_parsed_as s(:str, "foo\nbar")
          '"foo\\rbar"'.must_be_parsed_as s(:str, "foo\rbar")
          '"foo\\sbar"'.must_be_parsed_as s(:str, "foo\sbar")
          '"foo\\tbar"'.must_be_parsed_as s(:str, "foo\tbar")
          '"foo\\vbar"'.must_be_parsed_as s(:str, "foo\vbar")
        end

        it 'works with octal number escapes' do
          '"foo\\123bar"'.must_be_parsed_as s(:str, "foo\123bar")
          '"foo\\23bar"'.must_be_parsed_as s(:str, "foo\023bar")
          '"foo\\3bar"'.must_be_parsed_as s(:str, "foo\003bar")

          '"foo\\118bar"'.must_be_parsed_as s(:str, "foo\0118bar")
          '"foo\\18bar"'.must_be_parsed_as s(:str, "foo\0018bar")
        end

        it 'works with simple short hand control sequence escapes' do
          '"foo\\cabar"'.must_be_parsed_as s(:str, "foo\cabar")
          '"foo\\cZbar"'.must_be_parsed_as s(:str, "foo\cZbar")
        end

        it 'works with simple regular control sequence escapes' do
          '"foo\\C-abar"'.must_be_parsed_as s(:str, "foo\C-abar")
          '"foo\\C-Zbar"'.must_be_parsed_as s(:str, "foo\C-Zbar")
        end

        it 'works with unicode escapes' do
          '"foo\\u273bbar"'.must_be_parsed_as s(:str, 'foo✻bar')
        end

        it 'works with unicode escapes with braces' do
          '"foo\\u{273b}bar"'.must_be_parsed_as s(:str, 'foo✻bar')
        end

        it 'converts to unicode if possible' do
          '"2\302\275"'.must_be_parsed_as s(:str, '2½')
        end

        # TODO: Raise error instead
        it 'does not convert to unicode if result is not valid' do
          bytes = ['2'.ord, 0x82, 0o302, 0o275]
          string = bytes.pack('c4')
          '"2\x82\302\275"'.
            must_be_parsed_as s(:str, string)
        end
      end

      describe 'with interpolations' do
        describe 'containing just a literal string' do
          it 'performs no interpolation when it is at the end' do
            '"foo#{"bar"}"'.
              must_be_parsed_as s(:dstr,
                                  s(:str, 'foo'),
                                  s(:begin, s(:str, 'bar')))
          end

          it 'performs no interpolation when it is in the middle' do
            '"foo#{"bar"}baz"'.
              must_be_parsed_as s(:dstr,
                                  s(:str, 'foo'),
                                  s(:begin, s(:str, 'bar')),
                                  s(:str, 'baz'))
          end

          it 'performs no interpolation when it is at the start' do
            '"#{"foo"}bar"'.
              must_be_parsed_as s(:dstr,
                                  s(:begin, s(:str, 'foo')),
                                  s(:str, 'bar'))
          end
        end

        describe 'without braces' do
          it 'works for ivars' do
            "\"foo\#@bar\"".must_be_parsed_as s(:dstr,
                                                s(:str, 'foo'),
                                                s(:begin, s(:ivar, :@bar)))
          end

          it 'works for gvars' do
            "\"foo\#$bar\"".must_be_parsed_as s(:dstr,
                                                s(:str, 'foo'),
                                                s(:begin, s(:gvar, :$bar)))
          end

          it 'works for cvars' do
            "\"foo\#@@bar\"".must_be_parsed_as s(:dstr,
                                                 s(:str, 'foo'),
                                                 s(:begin, s(:cvar, :@@bar)))
          end
        end

        describe 'with braces' do
          it 'works for trivial interpolated strings' do
            '"#{foo}"'.
              must_be_parsed_as s(:dstr,
                                  s(:begin,
                                    s(:send, nil, :foo)))
          end

          it 'works for basic interpolated strings' do
            '"foo#{bar}"'.
              must_be_parsed_as s(:dstr,
                                  s(:str, 'foo'),
                                  s(:begin,
                                    s(:send, nil, :bar)))
          end

          it 'works for strings with several interpolations' do
            '"foo#{bar}baz#{qux}"'.
              must_be_parsed_as s(:dstr,
                                  s(:str, 'foo'),
                                  s(:begin, s(:send, nil, :bar)),
                                  s(:str, 'baz'),
                                  s(:begin, s(:send, nil, :qux)))
          end

          it 'correctly handles two interpolations in a row' do
            "\"\#{bar}\#{qux}\"".
              must_be_parsed_as s(:dstr,
                                  s(:begin, s(:send, nil, :bar)),
                                  s(:begin, s(:send, nil, :qux)))
          end

          it 'works with an empty interpolation' do
            "\"foo\#{}bar\"".
              must_be_parsed_as s(:dstr,
                                  s(:str, 'foo'),
                                  s(:begin),
                                  s(:str, 'bar'))
          end
        end
      end

      describe 'with interpolations and escape sequences' do
        it 'works when interpolations are followed by escape sequences' do
          '"#{foo}\\n"'.
            must_be_parsed_as s(:dstr,
                                s(:begin, s(:send, nil, :foo)),
                                s(:str, "\n"))
        end

        it 'works when interpolations contain a mix of other string-like literals' do
          '"#{[:foo, \'bar\']}\\n"'.
            must_be_parsed_as s(:dstr,
                                s(:begin, s(:array, s(:sym, :foo), s(:str, 'bar'))),
                                s(:str, "\n"))
        end

        it 'converts to unicode after interpolation' do
          '"#{foo}2\302\275"'.
            must_be_parsed_as s(:dstr,
                                s(:begin, s(:send, nil, :foo)),
                                s(:str, '2½'))
        end

        it 'convert null byte to unicode after interpolation' do
          '"#{foo}\0"'.
            must_be_parsed_as s(:dstr,
                                s(:begin, s(:send, nil, :foo)),
                                s(:str, "\u0000"))
        end
      end

      describe 'with single quoted strings' do
        it 'works with escaped single quotes' do
          "'foo\\'bar'".
            must_be_parsed_as s(:str, "foo'bar")
        end

        it 'works with embedded backslashes' do
          "'foo\\abar'".
            must_be_parsed_as s(:str, 'foo\abar')
        end

        it 'works with escaped embedded backslashes' do
          "'foo\\\\abar'".
            must_be_parsed_as s(:str, 'foo\abar')
        end

        it 'works with sequences of backslashes' do
          "'foo\\\\\\abar'".
            must_be_parsed_as s(:str, 'foo\\\\abar')
        end

        it 'does not process line continuation' do
          "'foo\\\nbar'".
            must_be_parsed_as s(:str, "foo\\\nbar")
        end
      end

      describe 'with %Q-delimited strings' do
        it 'works for the simple case' do
          '%Q[bar]'.
            must_be_parsed_as s(:str, 'bar')
        end

        it 'works for escape sequences' do
          '%Q[foo\\nbar]'.
            must_be_parsed_as s(:str, "foo\nbar")
        end

        it 'handles line continuation' do
          "%Q[foo\\\nbar]".
            must_be_parsed_as s(:str, 'foobar')
        end
      end

      describe 'with %-delimited strings' do
        it 'works for the simple case' do
          '%(bar)'.
            must_be_parsed_as s(:str, 'bar')
        end

        it 'works for escape sequences' do
          '%(foo\nbar)'.
            must_be_parsed_as s(:str, "foo\nbar")
        end

        it 'works for odd delimiters' do
          '%!foo\nbar!'.
            must_be_parsed_as s(:str, "foo\nbar")
        end
      end

      describe 'with string concatenation' do
        it 'makes a :dstr in the case of two simple literal strings' do
          '"foo" "bar"'.must_be_parsed_as s(:dstr,
                                            s(:str, 'foo'),
                                            s(:str, 'bar'))
        end

        it 'makes a :dstr when the right string has interpolations' do
          "\"foo\" \"bar\#{baz}\"".
            must_be_parsed_as s(:dstr,
                                s(:str, 'foo'),
                                s(:dstr,
                                  s(:str, 'bar'),
                                  s(:begin, s(:send, nil, :baz))))
        end

        describe 'when the left string has interpolations' do
          it 'makes a :dstr' do
            "\"foo\#{bar}\" \"baz\"".
              must_be_parsed_as s(:dstr,
                                  s(:dstr,
                                    s(:str, 'foo'),
                                    s(:begin, s(:send, nil, :bar))),
                                  s(:str, 'baz'))
          end

          it 'makes a :dstr with an empty string' do
            "\"foo\#{bar}\" \"\"".
              must_be_parsed_as s(:dstr,
                                  s(:dstr,
                                    s(:str, 'foo'),
                                    s(:begin, s(:send, nil, :bar))),
                                  s(:str, ''))
          end
        end

        describe 'when both strings have interpolations' do
          it 'makes a :dstr' do
            "\"foo\#{bar}\" \"baz\#{qux}\"".
              must_be_parsed_as s(:dstr,
                                  s(:dstr,
                                    s(:str, 'foo'),
                                    s(:begin, s(:send, nil, :bar))),
                                  s(:dstr,
                                    s(:str, 'baz'),
                                    s(:begin, s(:send, nil, :qux))))
          end

          it 'removes empty substrings from the concatenation' do
            "\"foo\#{bar}\" \"\#{qux}\"".
              must_be_parsed_as s(:dstr,
                                  s(:dstr,
                                    s(:str, 'foo'),
                                    s(:begin, s(:send, nil, :bar))),
                                  s(:dstr,
                                    s(:begin, s(:send, nil, :qux))))
          end
        end
      end

      describe 'for heredocs' do
        it 'works for the simple case' do
          "<<FOO\nbar\nFOO".
            must_be_parsed_as s(:str, "bar\n")
        end

        it 'works for the indentable case' do
          "<<-FOO\n  bar\n  FOO".
            must_be_parsed_as s(:str, "  bar\n")
        end

        it 'works for the automatically outdenting case' do
          skip 'This is not valid syntax below Ruby 2.3' if RUBY_VERSION < '2.3.0'
          "  <<~FOO\n  bar\n  FOO".
            must_be_parsed_as s(:str, "bar\n")
        end

        it 'works for escape sequences' do
          "<<FOO\nbar\\tbaz\nFOO".
            must_be_parsed_as s(:str, "bar\tbaz\n")
        end

        it 'does not unescape with single quoted version' do
          "<<'FOO'\nbar\\tbaz\nFOO".
            must_be_parsed_as s(:str, "bar\\tbaz\n")
        end

        it 'does not unescape with indentable single quoted version' do
          "<<-'FOO'\n  bar\\tbaz\n  FOO".
            must_be_parsed_as s(:str, "  bar\\tbaz\n")
        end

        it 'does not unescape the automatically outdenting single quoted version' do
          skip 'This is not valid syntax below Ruby 2.3' if RUBY_VERSION < '2.3.0'
          "<<~'FOO'\n  bar\\tbaz\n  FOO".
            must_be_parsed_as s(:str, "bar\\tbaz\n")
        end

        it 'handles line continuation' do
          "<<FOO\nbar\\\nbaz\nFOO".
            must_be_parsed_as s(:str, "barbaz\n")
        end

        it 'escapes line continuation' do
          "<<FOO\nbar\\\\\nbaz\nFOO".
            must_be_parsed_as s(:str, "bar\\\nbaz\n")
        end

        it 'does not convert to unicode even if possible' do
          "<<FOO\n2\\302\\275\nFOO".
            must_be_parsed_as s(:str, "2\xC2\xBD\n".force_encoding('ascii-8bit'))
        end
      end
    end

    describe 'for word list literals with %w delimiter' do
      it 'works for the simple case' do
        '%w(foo bar)'.
          must_be_parsed_as s(:array, s(:str, 'foo'), s(:str, 'bar'))
      end

      it 'does not perform interpolation' do
        '%w(foo\\nbar baz)'.
          must_be_parsed_as s(:array, s(:str, 'foo\\nbar'), s(:str, 'baz'))
      end

      it 'handles line continuation' do
        "%w(foo\\\nbar baz)".
          must_be_parsed_as s(:array, s(:str, "foo\nbar"), s(:str, 'baz'))
      end

      it 'handles escaped spaces' do
        '%w(foo bar\ baz)'.
          must_be_parsed_as s(:array, s(:str, 'foo'), s(:str, 'bar baz'))
      end
    end

    describe 'for word list literals with %W delimiter' do
      it 'works for the simple case' do
        '%W(foo bar)'.
          must_be_parsed_as s(:array, s(:str, 'foo'), s(:str, 'bar'))
      end

      it 'handles escaped spaces' do
        '%W(foo bar\ baz)'.
          must_be_parsed_as s(:array, s(:str, 'foo'), s(:str, 'bar baz'))
      end

      it 'correctly handles interpolation' do
        "%W(foo \#{bar} baz)".
          must_be_parsed_as  s(:array,
                               s(:str, 'foo'),
                               s(:dstr, s(:begin, s(:send, nil, :bar))),
                               s(:str, 'baz'))
      end

      it 'correctly handles braceless interpolation' do
        "%W(foo \#@bar baz)".
          must_be_parsed_as  s(:array,
                               s(:str, 'foo'),
                               s(:dstr, s(:begin, s(:ivar, :@bar))),
                               s(:str, 'baz'))
      end

      it 'correctly handles in-word interpolation' do
        "%W(foo \#{bar}baz)".
          must_be_parsed_as s(:array,
                              s(:str, 'foo'),
                              s(:dstr,
                                s(:begin, s(:send, nil, :bar)),
                                s(:str, 'baz')))
      end

      it 'correctly handles escape sequences' do
        '%W(foo\nbar baz)'.
          must_be_parsed_as s(:array,
                              s(:str, "foo\nbar"),
                              s(:str, 'baz'))
      end

      it 'correctly handles line continuation' do
        "%W(foo\\\nbar baz)".
          must_be_parsed_as s(:array,
                              s(:str, "foo\nbar"),
                              s(:str, 'baz'))
      end
    end

    describe 'for symbol list literals with %i delimiter' do
      it 'works for the simple case' do
        '%i(foo bar)'.
          must_be_parsed_as s(:array, s(:sym, :foo), s(:sym, :bar))
      end

      it 'does not perform interpolation' do
        '%i(foo\\nbar baz)'.
          must_be_parsed_as s(:array, s(:sym, :"foo\\nbar"), s(:sym, :baz))
      end

      it 'handles line continuation' do
        "%i(foo\\\nbar baz)".
          must_be_parsed_as s(:array, s(:sym, :"foo\nbar"), s(:sym, :baz))
      end
    end

    describe 'for symbol list literals with %I delimiter' do
      it 'works for the simple case' do
        '%I(foo bar)'.
          must_be_parsed_as s(:array, s(:sym, :foo), s(:sym, :bar))
      end

      it 'correctly handles escape sequences' do
        '%I(foo\nbar baz)'.
          must_be_parsed_as s(:array,
                              s(:sym, :"foo\nbar"),
                              s(:sym, :baz))
      end

      it 'correctly handles interpolation' do
        "%I(foo \#{bar} baz)".
          must_be_parsed_as s(:array,
                              s(:sym, :foo),
                              s(:dsym, s(:begin, s(:send, nil, :bar))),
                              s(:sym, :baz))
      end

      it 'correctly handles in-word interpolation' do
        "%I(foo \#{bar}baz)".
          must_be_parsed_as s(:array,
                              s(:sym, :foo),
                              s(:dsym,
                                s(:begin, s(:send, nil, :bar)),
                                s(:str, 'baz')))
      end

      it 'correctly handles line continuation' do
        "%I(foo\\\nbar baz)".
          must_be_parsed_as s(:array,
                              s(:sym, :"foo\nbar"),
                              s(:sym, :baz))
      end
    end

    describe 'for character literals' do
      it 'works for simple character literals' do
        '?a'.
          must_be_parsed_as s(:str, 'a')
      end

      it 'works for escaped character literals' do
        '?\\n'.
          must_be_parsed_as s(:str, "\n")
      end

      it 'works for escaped character literals with ctrl' do
        '?\\C-a'.
          must_be_parsed_as s(:str, "\u0001")
      end

      it 'works for escaped character literals with meta' do
        '?\\M-a'.
          must_be_parsed_as s(:str, [0xE1].pack('c'))
      end

      it 'works for escaped character literals with meta plus shorthand ctrl' do
        '?\\M-\\ca'.
          must_be_parsed_as s(:str, [0x81].pack('c'))
      end

      it 'works for escaped character literals with shorthand ctrl plus meta' do
        '?\\c\\M-a'.
          must_be_parsed_as s(:str, [0x81].pack('c'))
      end

      it 'works for escaped character literals with meta plus ctrl' do
        '?\\M-\\C-a'.
          must_be_parsed_as s(:str, [0x81].pack('c'))
      end

      it 'works for escaped character literals with ctrl plus meta' do
        '?\\C-\\M-a'.
          must_be_parsed_as s(:str, [0x81].pack('c'))
      end
    end

    describe 'for symbol literals' do
      it 'works for simple symbols' do
        ':foo'.
          must_be_parsed_as s(:sym, :foo)
      end

      it 'works for symbols that look like instance variable names' do
        ':@foo'.
          must_be_parsed_as s(:sym, :@foo)
      end

      it 'works for symbols that look like class names' do
        ':Foo'.
          must_be_parsed_as s(:sym, :Foo)
      end

      it 'works for simple dsyms' do
        ':"foo"'.
          must_be_parsed_as s(:sym, :foo)
      end

      it 'works for dsyms with interpolations' do
        ':"foo#{bar}"'.
          must_be_parsed_as s(:dsym,
                              s(:str, 'foo'),
                              s(:begin, s(:send, nil, :bar)))
      end

      it 'works for dsyms with interpolations at the start' do
        ':"#{bar}"'.
          must_be_parsed_as s(:dsym,
                              s(:begin, s(:send, nil, :bar)))
      end

      it 'works for dsyms with escape sequences' do
        ':"foo\nbar"'.
          must_be_parsed_as s(:sym, :"foo\nbar")
      end

      it 'works with single quoted dsyms' do
        ":'foo'".
          must_be_parsed_as s(:sym, :foo)
      end

      it 'works with single quoted dsyms with escaped single quotes' do
        ":'foo\\'bar'".
          must_be_parsed_as s(:sym, :'foo\'bar')
      end

      it 'works with single quoted dsyms with embedded backslashes' do
        ":'foo\\abar'".
          must_be_parsed_as s(:sym, :"foo\\abar")
      end
    end

    describe 'for backtick string literals' do
      it 'works for basic backtick strings' do
        '`foo`'.
          must_be_parsed_as s(:xstr, s(:str, 'foo'))
      end

      it 'works for interpolated backtick strings' do
        '`foo#{bar}`'.
          must_be_parsed_as s(:xstr,
                              s(:str, 'foo'),
                              s(:begin, s(:send, nil, :bar)))
      end

      it 'works for backtick strings interpolated at the start' do
        '`#{foo}`'.
          must_be_parsed_as s(:xstr,
                              s(:begin, s(:send, nil, :foo)))
      end

      it 'works for backtick strings with escape sequences' do
        '`foo\\n`'.
          must_be_parsed_as s(:xstr, s(:str, "foo\n"))
      end
    end

    describe 'for array literals' do
      it 'works for an empty array' do
        '[]'.
          must_be_parsed_as s(:array)
      end

      it 'works for a simple case with splat' do
        '[*foo]'.
          must_be_parsed_as s(:array,
                              s(:splat, s(:send, nil, :foo)))
      end

      it 'works for a multi-element case with splat' do
        '[foo, *bar]'.
          must_be_parsed_as s(:array,
                              s(:send, nil, :foo),
                              s(:splat, s(:send, nil, :bar)))
      end
    end

    describe 'for hash literals' do
      it 'works for an empty hash' do
        '{}'.
          must_be_parsed_as s(:hash)
      end

      it 'works for a hash with one pair' do
        '{foo => bar}'.
          must_be_parsed_as s(:hash,
                              s(:pair,
                                s(:send, nil, :foo),
                                s(:send, nil, :bar)))
      end

      it 'works for a hash with multiple pairs' do
        '{foo => bar, baz => qux}'.
          must_be_parsed_as s(:hash,
                              s(:pair,
                                s(:send, nil, :foo),
                                s(:send, nil, :bar)),
                              s(:pair,
                                s(:send, nil, :baz),
                                s(:send, nil, :qux)))
      end

      it 'works for a hash with label keys' do
        '{foo: bar, baz: qux}'.
          must_be_parsed_as s(:hash,
                              s(:pair,
                                s(:sym, :foo),
                                s(:send, nil, :bar)),
                              s(:pair,
                                s(:sym, :baz),
                                s(:send, nil, :qux)))
      end

      it 'works for a hash with dynamic label keys' do
        "{'foo': bar}".
          must_be_parsed_as s(:hash,
                              s(:pair,
                                s(:sym, :foo),
                                s(:send, nil, :bar)))
      end

      it 'works for a hash with splat' do
        '{foo: bar, baz: qux, **quux}'.
          must_be_parsed_as s(:hash,
                              s(:pair, s(:sym, :foo), s(:send, nil, :bar)),
                              s(:pair, s(:sym, :baz), s(:send, nil, :qux)),
                              s(:kwsplat, s(:send, nil, :quux)))
      end
    end

    describe 'for number literals' do
      it 'works for floats' do
        '3.14'.
          must_be_parsed_as s(:float, 3.14)
      end

      it 'works for octal integer literals' do
        '0700'.
          must_be_parsed_as s(:int, 448)
      end

      it 'handles negative sign for integers' do
        '-1'.
          must_be_parsed_as s(:int, -1)
      end

      it 'handles space after negative sign for integers' do
        '-1 '.
          must_be_parsed_as s(:int, -1)
      end

      it 'handles negative sign for floats' do
        '-3.14'.
          must_be_parsed_as s(:float, -3.14)
      end

      it 'handles space after negative sign for floats' do
        '-3.14 '.
          must_be_parsed_as s(:float, -3.14)
      end

      it 'handles positive sign' do
        '+1'.
          must_be_parsed_as s(:int, 1)
      end

      it 'works for rationals' do
        '1000r'.
          must_be_parsed_as s(:rational, 1000r)
      end
    end
  end
end
