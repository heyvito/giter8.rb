# frozen_string_literal: true

module Giter8
  # Literal represents a sequence of one or more characters not separated by
  # either a Template or Condition node.
  class Literal
    extend Forwardable
    attr_accessor :source, :line, :column, :value, :parent

    def initialize(value, parent, source, line, column)
      @source = source
      @line = line
      @column = column
      @value = value
      @parent = parent
    end

    def_delegators :@value, :empty?
    def_delegators :@value, :start_with?

    # Returns whether this node's value is comprised solely of a linebreak
    def linebreak?
      ["\r\n", "\n"].include? @value
    end

    def inspect
      parent = @parent
      parent = if parent.nil?
                 "nil"
               else
                 "#<#{@parent.class.name}:#{format("%08x", (@parent.object_id * 2))}>"
               end
      "#<#{self.class.name}:#{format("%08x", (object_id * 2))} line=#{@line} value=#{@value.inspect} parent=#{parent}>"
    end
  end
end
