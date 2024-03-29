# frozen_string_literal: true

require "ripper_parser/sexp_handlers/helper_methods"

require "ripper_parser/sexp_handlers/assignment"
require "ripper_parser/sexp_handlers/blocks"
require "ripper_parser/sexp_handlers/conditionals"
require "ripper_parser/sexp_handlers/literals"
require "ripper_parser/sexp_handlers/loops"
require "ripper_parser/sexp_handlers/method_calls"
require "ripper_parser/sexp_handlers/methods"
require "ripper_parser/sexp_handlers/operators"
require "ripper_parser/sexp_handlers/string_literals"

module RipperParser
  # Umbrella module for handlers of particular sexp types
  #
  # @api private
  module SexpHandlers
    def self.included(base)
      base.class_eval do
        include HelperMethods

        include Assignment
        include Blocks
        include Conditionals
        include Literals
        include Loops
        include MethodCalls
        include Methods
        include Operators
        include StringLiterals
      end
    end
  end
end
