# frozen_string_literal: true

describe RipperParser do
  it "knows its own version" do
    _(RipperParser::VERSION).wont_be_nil
  end
end
