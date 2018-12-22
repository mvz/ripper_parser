require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe 'Using RipperParser and Parser' do
  def to_line_numbers(exp)
    exp.map! do |sub_exp|
      if sub_exp.is_a? Sexp
        to_line_numbers sub_exp
      else
        sub_exp
      end
    end

    if exp.sexp_type == :scope
      exp
    else
      s(:line_number, exp.line, exp)
    end
  end

  let :newparser do
    RipperParser::Parser.new
  end

  let :oldparser do
    Parser::CurrentRuby
  end

  describe 'for a multi-line program' do
    let :program do
      <<-END
      class Foo
        def foo()
          bar()
          baz(qux)
        end
      end

      module Bar
        @@baz = {}
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
      formatted(imitation).must_equal formatted(original)
    end

    it 'gives the same result with line numbers' do
      formatted(to_line_numbers(imitation)).
        must_equal formatted(to_line_numbers(original))
    end
  end
end
