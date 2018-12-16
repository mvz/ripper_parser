require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe 'Using RipperParser and Parser' do
  let :newparser do
    RipperParser::Parser.new
  end

  let :oldparser do
    Parser::CurrentRuby
  end

  describe 'for a program with quite some comments' do
    let :program do
      <<-END
      # Foo
      class Foo
        # The foo
        # method
        def foo
          bar # bar
          # internal comment
        end

        def bar
          baz
        end
      end
      # Quux
      module Qux
        class Quux
          def bar
          end
          def baz
          end
        end
      end
      END
    end

    let :original do
      oldparser.parse program
    end

    let :imitation do
      newparser.parse program
    end

    it 'gives the same result' do
      imitation.must_equal original
    end

    it 'gives the same result with comments' do
      to_comments(imitation).must_equal to_comments(original)
    end
  end
end
