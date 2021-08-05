# frozen_string_literal: true

module Giter8
  # AST represents a set of nodes of a template file
  class AST
    extend Forwardable

    LEADING_LINEBREAK_REGEXP = /^\r?\n/.freeze

    def initialize
      @nodes = []
    end

    def_delegators :@nodes, :push, :<<, :each, :each_with_index, :empty?,
                   :length, :[], :last, :first, :map!, :map, :find, :shift,
                   :unshift

    # Returns whether this AST node is composed exclusively by Literals
    def pure_literal?
      all? { |v| v.is_a? Literal }
    end

    # Cleans up this AST's nodes in-place.
    def clean!
      @nodes = clean.instance_variable_get(:@nodes)
    end

    # Cleans leading linebreaks from the provided node
    def clean_conditional_ast(node)
      return node if node.empty? || !node.first.is_a?(Literal)

      cond = node.first
      cond.value.sub!(LEADING_LINEBREAK_REGEXP, "")
      node.shift
      node.unshift(cond) unless cond.value.empty?
      node
    end

    # clean_node attempts to sanitise a provide node under a given index
    # in this AST
    def clean_node(node, idx)
      if node.is_a?(Conditional)
        # Remove leading linebreak from ASTs inside conditionals
        node.cond_then = clean_conditional_ast(node.cond_then.clean)
        node.cond_else = clean_conditional_ast(node.cond_else.clean)

        # cond_else_if contains a list of Condition objects, which
        # need special handling.
        node.cond_else_if.clean!
      end

      if node.is_a?(Literal) && idx.positive? && self[idx - 1].is_a?(Conditional)
        # Remove leading linebreak from Literals following conditionals
        node.value.sub!(LEADING_LINEBREAK_REGEXP, "")
        return if node.value.empty?
      end
      node
    end

    # Returns a new AST node containing this node's after cleaning them.
    def clean
      ast = AST.new
      ast.push(*each_with_index.map(&method(:clean_node)).reject(&:nil?))
      ast
    end
  end
end
