# frozen_string_literal: true

module Giter8
  class Error < StandardError; end

  # PropertyNotFoundError indicates that a template referenced a variable not
  # defined by the property pairs provided to the renderer.
  class PropertyNotFoundError < Error
    def initialize(prop_name, source, line, column)
      super("Property `#{prop_name}' is not defined at #{source}:#{line}:#{column}")
    end
  end

  # FormatterNotFoundError indicates that a template variable referenced a
  # formatter not known by the renderer.
  class FormatterNotFoundError < Error
    def initialize(name, source, line, column)
      super("Formatter `#{name}' is not defined at #{source}:#{line}:#{column}")
    end
  end
end
