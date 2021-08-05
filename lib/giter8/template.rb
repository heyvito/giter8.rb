# frozen_string_literal: true

module Giter8
  # Template represents a Template variable in an AST. Contains a source file,
  # the line and column where the template begins, the variable name to be
  # looked up, a set of options, and the parent to which the node belongs to.
  class Template
    attr_accessor :source, :line, :column, :name, :options, :parent

    def initialize(name, options, parent, source, line, column)
      @source = source
      @line = line
      @column = column
      @name = name
      @options = options
      @parent = parent
    end
  end
end
