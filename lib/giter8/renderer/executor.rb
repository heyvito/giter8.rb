# frozen_string_literal: true

module Giter8
  # Module Renderer implements all mechanisms related to template rendering
  module Renderer
    # Executor implements methods for rendering remplates
    class Executor
      # Initializes the executor with a given Pairs set
      def initialize(props)
        @props = props
      end

      # Returns a string after rendering the provided AST tree with the Pairs
      # provided upon initialisation
      def exec(tree)
        result = StringIO.new
        exec_tree(tree, result)
        result.string
      end

      private

      # Returns a string array containing all formatting options present in the
      # template's format options.
      def extract_format_options(template)
        unless template.is_a? Giter8::Template
          raise Giter8::Error, "Can't call extract_format_options on non-template value"
        end
        return nil if template.options.empty?

        all_forms = template.options.fetch(:format)
        return nil if all_forms.nil?

        all_forms.split(",").map(&:strip)
      end

      # Execute all formatting helpers (if any) for a given Template instance,
      # returning the expanded variable value with all formatting applied.
      def run_methods(template)
        unless template.is_a? Giter8::Template
          raise(Giter8::Error,
                "Can't call run_methods on non-template value")
        end

        val = @props.fetch(template.name)
        if val.nil?
          raise Giter8::PropertyNotFoundError.new(template.name, template.source, template.line,
                                                  template.column)
        end

        opts = extract_format_options(template)
        unless opts.nil?
          return opts.inject(val) do |value, method_name|
            fn = HELPERS.fetch(method_name, nil)
            if fn.nil?
              raise Giter8::FormatterNotFoundError.new(method_name, template.source, template.line,
                                                       template.column)
            end

            fn.call(value)
          end
        end

        val
      end

      # Evaluates and returns a boolean value for a given Conditional instance
      # of an AST.
      def evaluate_conditional_expression(cond)
        val = @props.find_pair(cond.property)
        helper = cond.helper
        helper = helper.downcase

        return nil if %w[truthy present].include?(helper) && val.nil?

        raise Giter8::PropertyNotFoundError.new(cond.property, cond.source, cond.line, cond.column) if val.nil?

        case helper
        when "truthy"
          val.truthy?
        when "present"
          return nil if val.value.nil?

          !val.value.strip.empty?
        else
          raise "BUG: helper #{helper} allowed by parser, but not implemented by renderer"
        end
      end

      # Evaluates a given Conditional instance and writes a matching branch to
      # the provided Writer. Returns whether a branch was matched.
      def evaluate_conditional(cond, writer)
        unless cond.is_a? Giter8::Conditional
          raise Giter8::Error,
                "Can't call evaluate_conditional on non-conditional type"
        end

        ok = evaluate_conditional_expression(cond)
        if ok
          exec_tree(cond.cond_then, writer)
          return true
        end

        cond.cond_else_if.each do |inner_cond|
          return true if evaluate_conditional(inner_cond, writer)
        end

        unless cond.cond_else.nil?
          exec_tree(cond.cond_else, writer)
          return true
        end

        false
      end

      # Recursively iterate a provided AST tree and writes its results to the
      # provided writer.
      def exec_tree(tree, writer)
        tree.each do |node|
          case node
          when Giter8::Literal
            writer << node.value
          when Giter8::Template
            writer << run_methods(node)
          when Giter8::Conditional
            evaluate_conditional(node, writer)
          else
            raise Giter8::Error, "BUG: Unexpected node type #{node.class.name}"
          end
        end
      end
    end
  end
end
