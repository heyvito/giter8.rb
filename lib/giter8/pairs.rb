# frozen_string_literal: true

module Giter8
  # Pairs represents a set of property pairs
  class Pairs
    # Creates a new Pairs instance, optionally with a given map.
    def initialize(map = {})
      @pairs = map.map do |e|
        if e.is_a? Pair
          e
        else
          Pair.new(*e)
        end
      end
    end

    # Attempts to find a Pair instance with a given name among all propertines
    # in the current set.
    # Returns a Pair object, or nil, if the provided name does not match any
    # Pair.
    def find(name)
      v = find_pair(name.to_sym)
      return nil if v.nil?

      v.value
    end

    # Returns the value associated with a given name, or an optional default
    # argument. In case no default is provided, nil is returned.
    def fetch(name, default = nil)
      find(name) || default
    end

    # When a block is provided, invokes the block once for each Pair included in
    # this set. Otherwise, returns an Enumerator for this instance.
    def each(&block)
      @pairs.each(&block)
    end

    # Invokes a given block once for each element in this set, providing the
    # element's key and value as arguments, respectively.
    def each_pair
      each do |p|
        yield p.key, p.value
      end
    end

    # Returns a Pair value with a given name, or nil, in case no Pair matches
    # the provided name.
    def find_pair(name)
      @pairs.find { |e| e.key == name.to_sym }
    end

    # Returns the current props represented as a Hash
    def to_h
      @pairs.map { |e| [e.key, e.value] }.to_h
    end

    # Returns whether a Pair with the provided name exists in the set
    def key?(name)
      !find(name).nil?
    end

    # Merges a provided Hash or Pairs instance into the current set
    def merge(pairs)
      pairs = Pairs.new(pairs) if pairs.is_a? Hash

      pairs.each_pair do |k, v|
        pair = find_pair(k)
        if pair.nil?
          @pairs << Pair.new(k, v)
        else
          idx = @pairs.index(pair)
          pair.value = v
          @pairs[idx] = pair
        end
      end
    end
  end
end
