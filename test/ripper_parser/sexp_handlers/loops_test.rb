require File.expand_path('../../test_helper.rb', File.dirname(__FILE__))

describe RipperParser::Parser do
  describe '#parse' do
    describe 'for the while statement' do
      it 'works with do' do
        'while foo do; bar; end'.
          must_be_parsed_as s(:while,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar), true)
      end

      it 'works without do' do
        'while foo; bar; end'.
          must_be_parsed_as s(:while,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar), true)
      end

      it 'works in the single-line postfix case' do
        'foo while bar'.
          must_be_parsed_as s(:while,
                              s(:send, nil, :bar),
                              s(:send, nil, :foo), true)
      end

      it 'works in the block postfix case' do
        'begin; foo; end while bar'.
          must_be_parsed_as s(:while,
                              s(:send, nil, :bar),
                              s(:kwbegin, s(:send, nil, :foo)), false)
      end

      it 'handles a negative condition' do
        'while not foo; bar; end'.
          must_be_parsed_as s(:while,
                              s(:send, s(:send, nil, :foo), :!),
                              s(:send, nil, :bar), true)
      end

      it 'handles a negative condition in the postfix case' do
        'foo while not bar'.
          must_be_parsed_as s(:while,
                              s(:send, s(:send, nil, :bar), :!),
                              s(:send, nil, :foo), true)
      end

      it 'converts a negated match condition to :until' do
        'while foo !~ bar; baz; end'.
          must_be_parsed_as s(:until,
                              s(:send, s(:send, nil, :foo), :=~, s(:send, nil, :bar)),
                              s(:send, nil, :baz), true)
      end

      it 'converts a negated match condition to :until in the postfix case' do
        'baz while foo !~ bar'.
          must_be_parsed_as s(:until,
                              s(:send, s(:send, nil, :foo), :=~, s(:send, nil, :bar)),
                              s(:send, nil, :baz), true)
      end

      it 'works with begin..end block in condition' do
        'while begin foo end; bar; end'.
          must_be_parsed_as s(:while,
                              s(:kwbegin,
                                s(:send, nil, :foo)),
                              s(:send, nil, :bar), true)
      end

      it 'works with begin..end block in condition in the postfix case' do
        'foo while begin bar end'.
          must_be_parsed_as s(:while,
                              s(:kwbegin,
                                s(:send, nil, :bar)),
                              s(:send, nil, :foo), true)
      end
    end

    describe 'for the until statement' do
      it 'works in the prefix block case with do' do
        'until foo do; bar; end'.
          must_be_parsed_as s(:until,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar), true)
      end

      it 'works in the prefix block case without do' do
        'until foo; bar; end'.
          must_be_parsed_as s(:until,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar), true)
      end

      it 'works in the single-line postfix case' do
        'foo until bar'.
          must_be_parsed_as s(:until,
                              s(:send, nil, :bar),
                              s(:send, nil, :foo), true)
      end

      it 'works in the block postfix case' do
        'begin; foo; end until bar'.
          must_be_parsed_as s(:until,
                              s(:send, nil, :bar),
                              s(:kwbegin, s(:send, nil, :foo)), false)
      end

      it 'handles a negative condition' do
        'until not foo; bar; end'.
          must_be_parsed_as s(:until,
                              s(:send, s(:send, nil, :foo), :!),
                              s(:send, nil, :bar), true)
      end

      it 'handles a negative condition in the postfix case' do
        'foo until not bar'.
          must_be_parsed_as s(:until,
                              s(:send, s(:send, nil, :bar), :!),
                              s(:send, nil, :foo), true)
      end

      it 'converts a negated match condition to :while' do
        'until foo !~ bar; baz; end'.
          must_be_parsed_as s(:while,
                              s(:send, s(:send, nil, :foo), :=~, s(:send, nil, :bar)),
                              s(:send, nil, :baz), true)
      end

      it 'converts a negated match condition to :while in the postfix case' do
        'baz until foo !~ bar'.
          must_be_parsed_as s(:while,
                              s(:send, s(:send, nil, :foo), :=~, s(:send, nil, :bar)),
                              s(:send, nil, :baz), true)
      end

      it 'cleans up begin..end block in condition' do
        'until begin foo end; bar; end'.
          must_be_parsed_as s(:until,
                              s(:kwbegin, s(:send, nil, :foo)),
                              s(:send, nil, :bar), true)
      end

      it 'cleans up begin..end block in condition in the postfix case' do
        'foo until begin bar end'.
          must_be_parsed_as s(:until,
                              s(:kwbegin, s(:send, nil, :bar)),
                              s(:send, nil, :foo), true)
      end
    end

    describe 'for the for statement' do
      it 'works with a single assignment' do
        'for foo in bar; end'.
          must_be_parsed_as s(:for, s(:send, nil, :bar), s(:lvasgn, :foo))
      end

      it 'works with explicit multiple assignment' do
        'for foo, bar in baz; end'.
          must_be_parsed_as s(:for,
                              s(:send, nil, :baz),
                              s(:masgn,
                                s(:array,
                                  s(:lvasgn, :foo),
                                  s(:lvasgn, :bar))))
      end

      it 'works with multiple assignment with trailing comma' do
        'for foo, in bar; end'.
          must_be_parsed_as s(:for,
                              s(:send, nil, :bar),
                              s(:masgn,
                                s(:array,
                                  s(:lvasgn, :foo))))
      end
    end
  end
end
