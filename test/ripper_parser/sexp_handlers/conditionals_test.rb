require File.expand_path('../../test_helper.rb', File.dirname(__FILE__))

describe RipperParser::Parser do
  describe '#parse' do
    describe 'for regular if' do
      it 'works with a single statement' do
        'if foo; bar; end'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar),
                              nil)
      end

      it 'works with multiple statements' do
        'if foo; bar; baz; end'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              s(:begin,
                                s(:send, nil, :bar),
                                s(:send, nil, :baz)),
                              nil)
      end

      it 'works with zero statements' do
        'if foo; end'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              nil,
                              nil)
      end

      it 'works with a begin..end block' do
        'if foo; begin; bar; end; end'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              s(:kwbegin, s(:send, nil, :bar)),
                              nil)
      end

      it 'works with an else clause' do
        'if foo; bar; else; baz; end'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar),
                              s(:send, nil, :baz))
      end

      it 'works with an empty main clause' do
        'if foo; else; bar; end'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              nil,
                              s(:send, nil, :bar))
      end

      it 'works with an empty else clause' do
        'if foo; bar; else; end'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar),
                              nil)
      end

      it 'handles a negative condition correctly' do
        'if not foo; bar; end'.
          must_be_parsed_as s(:if,
                              s(:send, s(:send, nil, :foo), :!),
                              s(:send, nil, :bar),
                              nil)
      end

      it 'handles bare regex literal in condition' do
        'if /foo/; bar; end'.
          must_be_parsed_as s(:if,
                              s(:match_current_line,
                                s(:regexp,
                                  s(:str, 'foo'),
                                  s(:regopt))),
                              s(:send, nil, :bar), nil)
      end

      it 'handles interpolated regex in condition' do
        'if /#{foo}/; bar; end'.
          must_be_parsed_as s(:if,
                              s(:match_current_line,
                                s(:regexp,
                                  s(:begin,
                                    s(:send, nil, :foo)),
                                  s(:regopt))),
                              s(:send, nil, :bar), nil)
      end

      it 'handles block conditions' do
        'if (foo; bar); baz; end'.
          must_be_parsed_as s(:if,
                              s(:begin,
                                s(:send, nil, :foo),
                                s(:send, nil, :bar)),
                              s(:send, nil, :baz),
                              nil)
      end

      it 'converts :dot2 to :iflipflop' do
        'if foo..bar; baz; end'.
          must_be_parsed_as s(:if,
                              s(:iflipflop,
                                s(:send, nil, :foo),
                                s(:send, nil, :bar)),
                              s(:send, nil, :baz), nil)
      end

      it 'converts :dot3 to :eflipflop' do
        'if foo...bar; baz; end'.
          must_be_parsed_as s(:if,
                              s(:eflipflop,
                                s(:send, nil, :foo),
                                s(:send, nil, :bar)),
                              s(:send, nil, :baz), nil)
      end

      it 'handles negative match operator' do
        'if foo !~ bar; baz; else; qux; end'.
          must_be_parsed_as s(:if,
                              s(:send, s(:send, nil, :foo), :!~, s(:send, nil, :bar)),
                              s(:send, nil, :baz),
                              s(:send, nil, :qux))
      end

      it 'works with begin..end block in condition' do
        'if begin foo end; bar; end'.
          must_be_parsed_as s(:if,
                              s(:kwbegin,
                                s(:send, nil, :foo)),
                              s(:send, nil, :bar), nil)
      end

      it 'works with special conditions inside begin..end block' do
        'if begin foo..bar end; baz; end'.
          must_be_parsed_as s(:if,
                              s(:kwbegin,
                                s(:irange, s(:send, nil, :foo), s(:send, nil, :bar))),
                              s(:send, nil, :baz),
                              nil)
      end

      it 'works with assignment in the condition' do
        'if foo = bar; baz; end'.
          must_be_parsed_as s(:if,
                              s(:lvasgn, :foo,
                                s(:send, nil, :bar)),
                              s(:send, nil, :baz), nil)
      end

      it 'works with bracketed assignment in the condition' do
        'if (foo = bar); baz; end'.
          must_be_parsed_as s(:if,
                              s(:begin,
                                s(:lvasgn, :foo,
                                  s(:send, nil, :bar))),
                              s(:send, nil, :baz), nil)
      end
    end

    describe 'for postfix if' do
      it 'works with a simple condition' do
        'foo if bar'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :bar),
                              s(:send, nil, :foo),
                              nil)
      end

      it 'handles negative conditions' do
        'foo if not bar'.
          must_be_parsed_as s(:if,
                              s(:send, s(:send, nil, :bar), :!),
                              s(:send, nil, :foo),
                              nil)
      end

      it 'handles bare regex literal in condition' do
        'foo if /bar/'.
          must_be_parsed_as s(:if,
                              s(:match_current_line,
                                s(:regexp, s(:str, 'bar'), s(:regopt))),
                              s(:send, nil, :foo),
                              nil)
      end

      it 'handles interpolated regex in condition' do
        'foo if /#{bar}/'.
          must_be_parsed_as s(:if,
                              s(:match_current_line,
                                s(:regexp,
                                  s(:begin,
                                    s(:send, nil, :bar)),
                                  s(:regopt))),
                              s(:send, nil, :foo), nil)
      end

      it 'handles negative match operator' do
        'baz if foo !~ bar'.
          must_be_parsed_as s(:if,
                              s(:send, s(:send, nil, :foo), :!~, s(:send, nil, :bar)),
                              s(:send, nil, :baz),
                              nil)
      end

      it 'works with begin..end block in condition' do
        'foo if begin bar end'.
          must_be_parsed_as s(:if,
                              s(:kwbegin,
                                s(:send, nil, :bar)),
                              s(:send, nil, :foo), nil)
      end
    end

    describe 'for regular unless' do
      it 'works with a single statement' do
        'unless bar; foo; end'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :bar),
                              nil,
                              s(:send, nil, :foo))
      end

      it 'works with multiple statements' do
        'unless foo; bar; baz; end'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              nil,
                              s(:begin,
                                s(:send, nil, :bar),
                                s(:send, nil, :baz)))
      end

      it 'works with zero statements' do
        'unless foo; end'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              nil,
                              nil)
      end

      it 'works with an else clause' do
        'unless foo; bar; else; baz; end'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              s(:send, nil, :baz),
                              s(:send, nil, :bar))
      end

      it 'works with an empty main clause' do
        'unless foo; else; bar; end'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar),
                              nil)
      end

      it 'works with an empty else block' do
        'unless foo; bar; else; end'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              nil,
                              s(:send, nil, :bar))
      end

      it 'handles bare regex literal in condition' do
        'unless /foo/; bar; end'.
          must_be_parsed_as s(:if,
                              s(:match_current_line,
                                s(:regexp,
                                  s(:str, 'foo'),
                                  s(:regopt))),
                              nil,
                              s(:send, nil, :bar))
      end

      it 'handles interpolated regex in condition' do
        'unless /#{foo}/; bar; end'.
          must_be_parsed_as s(:if,
                              s(:match_current_line,
                                s(:regexp, s(:begin, s(:send, nil, :foo)), s(:regopt))),
                              nil,
                              s(:send, nil, :bar))
      end

      it 'handles negative match operator' do
        'unless foo !~ bar; baz; else; qux; end'.
          must_be_parsed_as s(:if,
                              s(:send, s(:send, nil, :foo), :!~, s(:send, nil, :bar)),
                              s(:send, nil, :qux),
                              s(:send, nil, :baz))
      end
    end

    describe 'for postfix unless' do
      it 'works with a simple condition' do
        'foo unless bar'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :bar),
                              nil,
                              s(:send, nil, :foo))
      end

      it 'handles bare regex literal in condition' do
        'foo unless /bar/'.
          must_be_parsed_as s(:if,
                              s(:match_current_line,
                                s(:regexp,
                                  s(:str, 'bar'),
                                  s(:regopt))),
                              nil,
                              s(:send, nil, :foo))
      end

      it 'handles interpolated regex in condition' do
        'foo unless /#{bar}/'.
          must_be_parsed_as s(:if,
                              s(:match_current_line,
                                s(:regexp,
                                  s(:begin,
                                    s(:send, nil, :bar)),
                                  s(:regopt))),
                              nil,
                              s(:send, nil, :foo))
      end

      it 'handles negative match operator' do
        'baz unless foo !~ bar'.
          must_be_parsed_as s(:if,
                              s(:send, s(:send, nil, :foo), :!~, s(:send, nil, :bar)),
                              nil,
                              s(:send, nil, :baz))
      end
    end

    describe 'for elsif' do
      it 'works with a single statement' do
        'if foo; bar; elsif baz; qux; end'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar),
                              s(:if,
                                s(:send, nil, :baz),
                                s(:send, nil, :qux),
                                nil))
      end

      it 'works with an empty consequesnt' do
        'if foo; bar; elsif baz; end'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar),
                              s(:if,
                                s(:send, nil, :baz),
                                nil,
                                nil))
      end

      it 'works with an empty else' do
        'if foo; bar; elsif baz; qux; else; end'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar),
                              s(:if,
                                s(:send, nil, :baz),
                                s(:send, nil, :qux),
                                nil))
      end

      it 'handles a negative condition correctly' do
        'if foo; bar; elsif not baz; qux; end'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar),
                              s(:if,
                                s(:send, s(:send, nil, :baz), :!),
                                s(:send, nil, :qux), nil))
      end

      it 'replaces :dot2 with :iflipflop' do
        'if foo; bar; elsif baz..qux; quuz; end'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar),
                              s(:if,
                                s(:iflipflop, s(:send, nil, :baz), s(:send, nil, :qux)),
                                s(:send, nil, :quuz), nil))
      end

      it 'does not rewrite the negative match operator' do
        'if foo; bar; elsif baz !~ qux; quuz; end'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar),
                              s(:if,
                                s(:send,
                                  s(:send, nil, :baz),
                                  :!~,
                                  s(:send, nil, :qux)),
                                s(:send, nil, :quuz),
                                nil))
      end

      it 'works with begin..end block in condition' do
        'if foo; bar; elsif begin baz end; qux; end'.
          must_be_parsed_as s(:if,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar),
                              s(:if,
                                s(:kwbegin,
                                  s(:send, nil, :baz)),
                                s(:send, nil, :qux),
                                nil))
      end
    end

    describe 'for case block' do
      it 'works with a single when clause' do
        'case foo; when bar; baz; end'.
          must_be_parsed_as s(:case,
                              s(:send, nil, :foo),
                              s(:when,
                                s(:send, nil, :bar),
                                s(:send, nil, :baz)),
                              nil)
      end

      it 'works with multiple when clauses' do
        'case foo; when bar; baz; when qux; quux; end'.
          must_be_parsed_as s(:case,
                              s(:send, nil, :foo),
                              s(:when,
                                s(:send, nil, :bar),
                                s(:send, nil, :baz)),
                              s(:when,
                                s(:send, nil, :qux),
                                s(:send, nil, :quux)),
                              nil)
      end

      it 'works with multiple statements in the when block' do
        'case foo; when bar; baz; qux; end'.
          must_be_parsed_as s(:case,
                              s(:send, nil, :foo),
                              s(:when,
                                s(:send, nil, :bar),
                                s(:begin,
                                  s(:send, nil, :baz),
                                  s(:send, nil, :qux))),
                              nil)
      end

      it 'works with an else clause' do
        'case foo; when bar; baz; else; qux; end'.
          must_be_parsed_as s(:case,
                              s(:send, nil, :foo),
                              s(:when,
                                s(:send, nil, :bar),
                                s(:send, nil, :baz)),
                              s(:send, nil, :qux))
      end

      it 'works with multiple statements in the else block' do
        'case foo; when bar; baz; else; qux; quuz end'.
          must_be_parsed_as s(:case,
                              s(:send, nil, :foo),
                              s(:when,
                                s(:send, nil, :bar),
                                s(:send, nil, :baz)),
                              s(:begin,
                                s(:send, nil, :qux),
                                s(:send, nil, :quuz)))
      end

      it 'works with an empty when block' do
        'case foo; when bar; end'.
          must_be_parsed_as s(:case,
                              s(:send, nil, :foo),
                              s(:when, s(:send, nil, :bar), nil),
                              nil)
      end

      it 'works with an empty else block' do
        'case foo; when bar; baz; else; end'.
          must_be_parsed_as s(:case,
                              s(:send, nil, :foo),
                              s(:when,
                                s(:send, nil, :bar),
                                s(:send, nil, :baz)),
                              nil)
      end

      it 'works with a splat in the when clause' do
        'case foo; when *bar; baz; end'.
          must_be_parsed_as s(:case,
                              s(:send, nil, :foo),
                              s(:when,
                                s(:splat, s(:send, nil, :bar)),
                                s(:send, nil, :baz)),
                              nil)
      end
    end
  end
end
