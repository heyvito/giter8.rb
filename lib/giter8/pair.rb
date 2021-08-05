# frozen_string_literal: true

module Giter8
  # Pair represent a key-value property pair
  class Pair
    PLAIN_KEY = /^[A-Za-z_][A-Za-z0-9_]*$/.freeze

    attr_accessor :key, :value

    def initialize(key, value)
      key = key.to_sym if !key.is_a?(Symbol) && PLAIN_KEY.match?(key)

      @key = key
      @value = value
    end

    # Determines whether the Pair's value contains a truthy value.
    # See Conditional.truthy?
    def truthy?
      Conditional.truthy? @value
    end

    def ==(other)
      same_pair = other.is_a?(Pair) && other.key == @key && other.value == @value
      same_hash = other.is_a?(Hash) && other == { @key => @value }
      same_hash || same_pair
    end
  end
end
