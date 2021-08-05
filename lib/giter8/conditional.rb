# frozen_string_literal: true

module Giter8
  # Represents a conditional structure in an AST
  class Conditional
    attr_accessor :source, :line, :column, :property, :helper, :cond_then,
                  :cond_else_if, :cond_else, :parent

    TRUTHY_VALUES = %w[yes y true].freeze

    # Returns whether a provided value is considered as "truthy". Giter8
    # assumes the values "yes", "y", and "true" as true. Any other value
    # is assumed to be false.
    def self.truthy?(value)
      if value.nil?
        nil
      elsif value.is_a? Literal
        truthy?(value.value)
      elsif value.is_a? String
        TRUTHY_VALUES.any? { |e| e.casecmp(value).zero? }
      end
    end

    def initialize(property, helper, parent, source, line, column)
      @source = source
      @line = line
      @column = column
      @property = property
      @helper = helper
      @parent = parent

      @cond_then = AST.new
      @cond_else_if = AST.new
      @cond_else = AST.new
    end

    # Cleans this Conditional's branches by calling AST#clean, and returns a
    # copy of this instance.
    def clean
      cond = Conditional.new(@property, @helper, @parent, @source, @line, @column)

      cond.cond_then = @cond_then.clean
      cond.cond_else = @cond_else.clean
      cond.cond_else_if = @cond_else_if.clean

      cond
    end

    # clean! executes the same operation as #clean, but updates this instance
    # instead of returning a copy.
    def clean!
      @cond_then = @cond_then.clean
      @cond_else = @cond_else.clean
      @cond_else_if = @cond_else_if.clean
    end
  end
end
