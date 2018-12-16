require File.expand_path('../../test_helper.rb', File.dirname(__FILE__))

describe RipperParser::Parser do
  describe '#parse' do
    describe 'for negated operators' do
      specify do
        'foo !~ bar'.must_be_parsed_as s(:not,
                                         s(:send,
                                           s(:send, nil, :foo),
                                           :=~,
                                           s(:send, nil, :bar)))
      end
    end

    describe 'for boolean operators' do
      it 'handles :and' do
        'foo and bar'.
          must_be_parsed_as s(:and,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar))
      end

      it 'handles double :and' do
        'foo and bar and baz'.
          must_be_parsed_as s(:and,
                              s(:send, nil, :foo),
                              s(:and,
                                s(:send, nil, :bar),
                                s(:send, nil, :baz)))
      end

      it 'handles :or' do
        'foo or bar'.
          must_be_parsed_as s(:or,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar))
      end

      it 'handles double :or' do
        'foo or bar or baz'.
          must_be_parsed_as s(:or,
                              s(:send, nil, :foo),
                              s(:or,
                                s(:send, nil, :bar),
                                s(:send, nil, :baz)))
      end

      it 'handles :or after :and' do
        'foo and bar or baz'.
          must_be_parsed_as s(:or,
                              s(:and,
                                s(:send, nil, :foo),
                                s(:send, nil, :bar)),
                              s(:send, nil, :baz))
      end

      it 'handles :and after :or' do
        'foo or bar and baz'.
          must_be_parsed_as s(:and,
                              s(:or,
                                s(:send, nil, :foo),
                                s(:send, nil, :bar)),
                              s(:send, nil, :baz))
      end

      it 'converts :&& to :and' do
        'foo && bar'.
          must_be_parsed_as s(:and,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar))
      end

      it 'handles :|| after :&&' do
        'foo && bar || baz'.
          must_be_parsed_as s(:or,
                              s(:and,
                                s(:send, nil, :foo),
                                s(:send, nil, :bar)),
                              s(:send, nil, :baz))
      end

      it 'handles :&& after :||' do
        'foo || bar && baz'.
          must_be_parsed_as s(:or,
                              s(:send, nil, :foo),
                              s(:and,
                                s(:send, nil, :bar),
                                s(:send, nil, :baz)))
      end

      it 'handles :|| with parentheses' do
        '(foo || bar) || baz'.
          must_be_parsed_as s(:or,
                              s(:or,
                                s(:send, nil, :foo),
                                s(:send, nil, :bar)),
                              s(:send, nil, :baz))
      end

      it 'handles nested :|| with parentheses' do
        'foo || (bar || baz) || qux'.
          must_be_parsed_as  s(:or,
                               s(:send, nil, :foo),
                               s(:or,
                                 s(:or, s(:send, nil, :bar), s(:send, nil, :baz)),
                                 s(:send, nil, :qux)))
      end

      it 'converts :|| to :or' do
        'foo || bar'.
          must_be_parsed_as s(:or,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar))
      end

      it 'handles triple :and' do
        'foo and bar and baz and qux'.
          must_be_parsed_as s(:and,
                              s(:send, nil, :foo),
                              s(:and,
                                s(:send, nil, :bar),
                                s(:and,
                                  s(:send, nil, :baz),
                                  s(:send, nil, :qux))))
      end

      it 'handles triple :&&' do
        'foo && bar && baz && qux'.
          must_be_parsed_as s(:and,
                              s(:send, nil, :foo),
                              s(:and,
                                s(:send, nil, :bar),
                                s(:and,
                                  s(:send, nil, :baz),
                                  s(:send, nil, :qux))))
      end
    end

    describe 'for the range operator' do
      it 'handles positive number literals' do
        '1..2'.
          must_be_parsed_as s(:irange,
                              s(:int, 1),
                              s(:int, 2))
      end

      it 'handles negative number literals' do
        '-1..-2'.
          must_be_parsed_as s(:irange,
                              s(:int, -1),
                              s(:int, -2))
      end

      it 'handles float literals' do
        '1.0..2.0'.
          must_be_parsed_as s(:irange,
                              s(:lit, 1.0),
                              s(:lit, 2.0))
      end

      it 'handles string literals' do
        "'a'..'z'".
          must_be_parsed_as s(:irange,
                              s(:str, 'a'),
                              s(:str, 'z'))
      end

      it 'handles non-literals' do
        'foo..bar'.
          must_be_parsed_as s(:irange,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar))
      end
    end

    describe 'for the exclusive range operator' do
      it 'handles positive number literals' do
        '1...2'.
          must_be_parsed_as s(:erange,
                              s(:int, 1),
                              s(:int, 2))
      end

      it 'handles negative number literals' do
        '-1...-2'.
          must_be_parsed_as s(:erange,
                              s(:int, -1),
                              s(:int, -2))
      end

      it 'handles float literals' do
        '1.0...2.0'.
          must_be_parsed_as s(:erange,
                              s(:lit, 1.0),
                              s(:lit, 2.0))
      end

      it 'handles string literals' do
        "'a'...'z'".
          must_be_parsed_as s(:erange,
                              s(:str, 'a'),
                              s(:str, 'z'))
      end

      it 'handles non-literals' do
        'foo...bar'.
          must_be_parsed_as s(:erange,
                              s(:send, nil, :foo),
                              s(:send, nil, :bar))
      end
    end

    describe 'for unary numerical operators' do
      it 'handles unary minus with an integer literal' do
        '- 1'.must_be_parsed_as s(:send, s(:int, 1), :-@)
      end

      it 'handles unary minus with a float literal' do
        '- 3.14'.must_be_parsed_as s(:send, s(:lit, 3.14), :-@)
      end

      it 'handles unary minus with a non-literal' do
        '-foo'.
          must_be_parsed_as s(:send,
                              s(:send, nil, :foo),
                              :-@)
      end

      it 'handles unary minus with a negative number literal' do
        '- -1'.must_be_parsed_as s(:send, s(:int, -1), :-@)
      end

      it 'handles unary plus with a number literal' do
        '+ 1'.must_be_parsed_as s(:send, s(:int, 1), :+@)
      end

      it 'handles unary plus with a non-literal' do
        '+foo'.
          must_be_parsed_as s(:send,
                              s(:send, nil, :foo),
                              :+@)
      end
    end
  end
end
