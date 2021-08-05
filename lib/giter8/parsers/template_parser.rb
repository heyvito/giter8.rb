# frozen_string_literal: true

module Giter8
  module Parsers
    # TemplateParser implements the main FSM to parse Giter8 templates
    class TemplateParser
      STATE_LITERAL                               = 1
      STATE_TEMPLATE_NAME                         = 2
      STATE_TEMPLATE_COMBINED_FORMATTER           = 3
      STATE_TEMPLATE_CONDITIONAL_EXPRESSION       = 4
      STATE_TEMPLATE_CONDITIONAL_EXPRESSION_END   = 5
      STATE_TEMPLATE_CONDITIONAL_THEN             = 6
      STATE_TEMPLATE_CONDITIONAL_ELSE_IF          = 7
      STATE_TEMPLATE_CONDITIONAL_ELSE             = 8
      STATE_TEMPLATE_OPTION_NAME                  = 9
      STATE_TEMPLATE_OPTION_VALUE_BEGIN           = 10
      STATE_TEMPLATE_OPTION_VALUE                 = 11
      STATE_TEMPLATE_OPTION_OR_END                = 12
      STATE_THEN_OR_ELSE_IF = [STATE_TEMPLATE_CONDITIONAL_THEN, STATE_TEMPLATE_CONDITIONAL_ELSE_IF].freeze

      STATE_NAMES = {
        STATE_LITERAL => "STATE_LITERAL",
        STATE_TEMPLATE_NAME => "STATE_TEMPLATE_NAME",
        STATE_TEMPLATE_COMBINED_FORMATTER => "STATE_TEMPLATE_COMBINED_FORMATTER",
        STATE_TEMPLATE_CONDITIONAL_EXPRESSION => "STATE_TEMPLATE_CONDITIONAL_EXPRESSION",
        STATE_TEMPLATE_CONDITIONAL_EXPRESSION_END => "STATE_TEMPLATE_CONDITIONAL_EXPRESSION_END",
        STATE_TEMPLATE_CONDITIONAL_THEN => "STATE_TEMPLATE_CONDITIONAL_THEN",
        STATE_TEMPLATE_CONDITIONAL_ELSE_IF => "STATE_TEMPLATE_CONDITIONAL_ELSE_IF",
        STATE_TEMPLATE_CONDITIONAL_ELSE => "STATE_TEMPLATE_CONDITIONAL_ELSE",
        STATE_TEMPLATE_OPTION_NAME => "STATE_TEMPLATE_OPTION_NAME",
        STATE_TEMPLATE_OPTION_VALUE_BEGIN => "STATE_TEMPLATE_OPTION_VALUE_BEGIN",
        STATE_TEMPLATE_OPTION_VALUE => "STATE_TEMPLATE_OPTION_VALUE",
        STATE_TEMPLATE_OPTION_OR_END => "STATE_TEMPLATE_OPTION_OR_END"
      }.freeze

      ESCAPE = "\\"
      DELIM  = "$"
      NEWLINE = "\n"
      SEMICOLON = ";"
      EQUALS = "="
      QUOT = '"'
      COMMA = ","
      SPACE = " "
      HTAB = "\t"
      LPAREN = "("
      RPAREN = ")"
      DOT = "."
      UNDESCORE = "_"
      DASH = "-"
      TRUTHY = "truthy"
      PRESENT = "present"
      VALID_LETTERS = (("a".."z").to_a + ("A".."Z").to_a).freeze
      VALID_DIGITS = ("0".."9").to_a.freeze

      VALID_COMPARATORS = [TRUTHY, PRESENT].freeze

      # Parses a given template string with provided options. Options is a
      # hash that currently only supports the :source key, which must be the
      # name of the file being parsed. This key is used to identify any errors
      # whilst parsing the contents and will be provided on any raised errors.
      # Returns an AST instance of the provided template string.
      def self.parse(template, opts = {})
        new(opts).parse(template)
      end

      # Initialises a new TemplateParser instance.
      # See also: TemplateParser.parse
      def initialize(opts = {})
        @ast = AST.new
        @tmp = []
        @template_name = []
        @option_name = []
        @option_value = []
        @template_options = {}
        @state_stack = []
        @state = STATE_LITERAL
        @last_chr = ""
        @debug = false
        @source = opts[:source] || "unknown"
        @line = 1
        @column = 0
        @anchors = {
          template_name: [0, 0],
          conditional: [0, 0]
        }
      end

      # Enables debugging logs for this instance. Contents will be written to
      # the standard output.
      def debug!
        @debug = true
      end

      # Returns an AST object of a provided string. This consumes each character
      # within the provided data.
      def parse(data)
        debug("begin parsing source `#{@source}'")
        data.chars.each do |chr|
          chr = chr.chr

          pchr = chr
          pchr = '\n' if pchr == NEWLINE
          debug("CHR: #{pchr}, STATE: #{state_name(@state)}")

          consume(chr)

          @column += 1
          if chr == NEWLINE
            @column = 0
            @line += 1
          end
          @last_chr = chr
        end

        unexpected_eof if @state != STATE_LITERAL

        commit_literal

        debug("finished parsing `#{@source}'")
        @ast.clean
      end

      private

      def debug(msg)
        puts "DEBUG: #{msg}" if @debug
      end

      # Returns whether the provided character is a space or horizontal tab
      def space?(chr)
        [SPACE, HTAB].include?(chr)
      end

      # Returns whether the provided character is between the a-z, A-Z range.
      def valid_letter?(chr)
        VALID_LETTERS.include? chr
      end

      # Returns the name of a given state, or UNDEFINED in case the state is not
      # known.
      def state_name(state)
        STATE_NAMES.fetch(state, "UNDEFINED")
      end

      # Returns the representation of the current stack as an array of Strings
      def stack_repr
        @state_stack.map { |s| state_name s }
      end

      # Pushes the current state into the state stack for later restoring
      def push_stack
        @state_stack << @state
        debug("STS: PUSH [#{stack_repr}]")
      end

      # Defines the current FSM state.
      def transition(state)
        debug("STT: Transitioning #{state_name(@state)} -> #{state_name(state)}")
        @state = state
      end

      # Restores the FSM state created by push_stack.
      # Raises an error in case the stack is empty.
      def pop_stack
        raise Giter8::Error, "BUG: Attempt to pop state stack beyond limit" if @state_stack.empty?

        state = @state_stack.pop
        debug("SRS: POP [#{stack_repr}]")
        transition state
      end

      # Replaces the last state in the state stack by the one provided.
      # Raises an error in case the stack is empty.
      def replace_stack(state)
        raise Giter8::Error, "BUG: Attempt to replace on empty stack" if @state_stack.empty?

        @state_stack.pop
        @state_stack.push(state)
        debug("SRS: REPLACE #{stack_repr}")
      end

      # Returns the latest stack value
      def current_stack
        @state_stack.last
      end

      # Pushes a given AST node into the correct container. When evaluating a
      # conditional "else" of "else if" branch, pushes to the Conditional's
      # branch. Otherwise pushes the the main AST list.
      def push_ast(node)
        debug("AST: PUSH_AST STACK: #{stack_repr} STATE: #{state_name @state}")
        s = current_stack
        if s.nil?
          @ast << node
        elsif STATE_THEN_OR_ELSE_IF.include? s
          @current_conditional.cond_then.push(node)
        else
          @current_conditional.cond_else.push(node)
        end
      end

      # Automatically pushes a Literal to the correct container, if any Literal
      # is temporarily stored within the FSM.
      def commit_literal
        return if @tmp.empty?

        push_ast(Literal.new(@tmp.join, @current_conditional, @source, @line, @column))
        @tmp = []
      end

      # Automatically commits a Template object to the correct container, if any
      # template is temporarily stored within the FSM.
      def commit_template
        return if @template_name.empty?

        push_ast(Template.new(
                   @template_name.join.strip,
                   @template_options,
                   @current_conditional,
                   @source,
                   *@anchors[:template_name]
                 ))

        @template_name = []
        @template_options = []
      end

      # Commits a template option currently being processed by the FSM, if any.
      # This automatically converts the option key's to a symbol in case it
      # begins by a letter (Between A-Z, case insensitive) and is followed by
      # letters, numbers and underscores.
      def commit_template_option
        return if @option_name.empty?

        key = @option_name.join.strip
        key = key.to_sym if /^[A-Za-z][A-Za-z0-9_]+$/.match?(key)
        @template_options[key] = @option_value.join.strip
        @option_name = []
        @option_value = []
      end

      # Initializes and pushes a Conditional object to the FSM's AST tree
      def prepare_conditional
        expr = @template_name.join
        separator_idx = expr.index(DOT)
        invalid_cond_expression(expr) if separator_idx.nil?

        prop = expr[0...separator_idx]
        helper = expr[separator_idx + 1..]
        unsupported_cond_helper(helper) unless VALID_COMPARATORS.include? helper

        cond = Conditional.new(
          prop,
          helper,
          @current_conditional,
          @source,
          *@anchors[:conditional]
        )
        ls = current_stack
        debug("CND: Current state: #{state_name(@state)}, ls: #{state_name(ls)}")
        case ls
        when STATE_TEMPLATE_CONDITIONAL_THEN
          if @state_stack.length > 1
            @current_conditional.cond_then.push(cond)
          else
            @ast << cond
          end
        when STATE_TEMPLATE_CONDITIONAL_ELSE_IF
          @current_conditional.cond_else_if.push cond
        end
        @current_conditional = cond
        @template_name = []
      end

      # Returns the current FSM's location as a string representation in the
      # format SOURCE_FILE_NAME:LINE:COLUMN
      def location
        "#{@source}:#{@line}:#{@column}"
      end

      # Raises a new "Unexpected token" error indicating a given token and
      # automatically including the current FSM's location.
      def unexpected_token(token)
        raise Giter8::Error, "Unexpected token `#{token}' at #{location}"
      end

      # Raises a new "Unexpected linebrak" error indicating current FSM's
      # location.
      def unexpected_line_break
        raise Giter8::Error, "Unexpected linebreak at #{location}"
      end

      # Raises a new "Unexpected keyword" error indicating a given keyword and
      # automatically including the current FSM's location.
      def unexpected_keyword(keyword)
        raise Giter8::Error, "Unexpected keyword `#{keyword}' at #{location}"
      end

      # Raises a new "Unexpected conditional expression" error indicating a
      # given expression and automatically including the current FSM's location.
      def invalid_cond_expr(expr)
        raise Giter8::Error, "Unexpected conditional expression `#{expr}' at #{location}"
      end

      # Raises a new "Unsupported token" error indicating a given expression and
      # automatically including the current FSM's location.
      def unsupported_cond_helper(name)
        raise Giter8::Error, "Unsupported conditional expression `#{name}' at #{location}"
      end

      # Raises a new "Unexpected EOF" error including the current FSM's
      # location.
      def unexpected_eof
        raise Giter8::Error, "Unexpected EOF at #{location}"
      end

      # Returns whether a given character may be used as part of a template
      # name. Names may be composed of letters (a-z, case insensitive), digits,
      # dashes and underscores.
      def valid_name_char?(chr)
        VALID_LETTERS.include?(chr) ||
          VALID_DIGITS.include?(chr) ||
          chr == DASH ||
          chr == UNDESCORE
      end

      # Consume is the main dispatcher for the FSM, invoking a specific method
      # for each state.
      def consume(chr)
        case @state
        when STATE_LITERAL
          consume_literal(chr)
        when STATE_TEMPLATE_NAME
          consume_template_name(chr)
        when STATE_TEMPLATE_COMBINED_FORMATTER
          consume_combined_formatter(chr)
        when STATE_TEMPLATE_CONDITIONAL_EXPRESSION
          consume_cond_expr(chr)
        when STATE_TEMPLATE_CONDITIONAL_EXPRESSION_END
          consume_cond_expr_end(chr)
        when STATE_TEMPLATE_OPTION_NAME
          consume_option_name(chr)
        when STATE_TEMPLATE_OPTION_VALUE_BEGIN
          consume_option_value_begin(chr)
        when STATE_TEMPLATE_OPTION_VALUE
          consume_option_value(chr)
        when STATE_TEMPLATE_OPTION_OR_END
          consume_option_or_end(chr)
        else
          raise Giter8::Error, "BUG: Unexpected state #{STATE_NAMES.fetch(@state, "UNDEFINED")}"
        end
      end

      # Consumes a given character as a Literal until a delimiter value is
      # found
      def consume_literal(chr)
        if chr == DELIM && @last_chr != ESCAPE
          commit_literal
          @anchors[:template_name] = [@line, @column]
          transition(STATE_TEMPLATE_NAME)
          return
        elsif chr == DELIM && @last_chr == ESCAPE
          @tmp.pop
        end
        @tmp.push(chr)
      end

      # Consumes a template name until a delimiter or semicolon is reached.
      # Raises "unexpected token" in case a space if found, and "unexpected
      # linebreak" in case a newline is reached. This automatically handles
      # conditionals using delimiters in case a left paren is reached,
      # invoking the related #consume_lparen method.
      def consume_template_name(chr)
        case chr
        when DELIM
          return consume_delim
        when SPACE
          unexpected_token(SPACE)
        when SEMICOLON
          return transition(STATE_TEMPLATE_OPTION_NAME)
        when NEWLINE
          unexpected_line_break
        end

        return consume_lparen if chr == LPAREN && %w[if elseif].include?(@template_name.join)

        unexpected_token(chr) if @template_name.length.zero? && !valid_letter?(chr)

        if chr == UNDESCORE && @last_chr == UNDESCORE
          @template_name.pop
          transition(STATE_TEMPLATE_COMBINED_FORMATTER)
          @tmp = []
          return
        end

        unexpected_token(chr) unless valid_name_char?(chr)

        @template_name.push(chr)
      end

      # Consumes a delimiter within a TemplateName state. This automatically
      # performs checks for conditional expressions compliance.
      def consume_delim
        unexpected_token(DELIM) if @template_name.empty? && chr == DELIM

        current_name = @template_name.join

        case current_name
        when "if"
          unexpected_keyword(current_name)

        when "else"
          unexpected_keyword(current_name) if @state_stack.empty?

          if current_stack == STATE_TEMPLATE_CONDITIONAL_ELSE_IF
            parent = @current_conditional.parent
            raise "BUG: ElseIf without parent" if parent.nil?
            raise "BUG: ElseIf without conditional parent" unless parent.is_a? Conditional

            @current_conditional = parent
          end

          replace_stack STATE_TEMPLATE_CONDITIONAL_ELSE
          transition STATE_LITERAL
          @template_name = []
          nil

        when "endif"
          unexpected_keyword(current_name) if @state_stack.empty?

          pop_stack
          prev_cond = @current_conditional.parent
          if prev_cond.nil?
            @current_conditional = nil
          elsif !prev_cond.is_a?(Conditional)
            raise "BUG: Parent is not conditional"
          end
          @current_conditional = prev_cond
          transition STATE_LITERAL
          @template_name = []
          return nil
        end

        commit_template
        transition STATE_LITERAL
      end

      # Consumes a left-paren inside a template name, handling if and elseif
      # expressions
      def consume_lparen
        if @template_name.join == "if"
          @anchors[:conditional] = [@line, @column]
          transition STATE_TEMPLATE_CONDITIONAL_THEN
        else
          # Transitioning to ElseIf...
          if @state_stack.empty? || current_stack == STATE_TEMPLATE_CONDITIONAL_ELSE
            # At this point, we either have an elseif out of an if structure,
            # or we have an elseif after an else. Both are invalid.
            unexpected_keyword "elseif"
          end
          pop_stack # Stack will contain a STATE_TEMPLATE_CONDITIONAL_THEN
          # Here we pop it, so we chan push the ELSE_IF. Otherwise,
          # following nodes will be assumed as pertaining to that
          # conditional's "then" clause.
          transition STATE_TEMPLATE_CONDITIONAL_ELSE_IF
        end

        push_stack
        transition(STATE_TEMPLATE_CONDITIONAL_EXPRESSION)
        @template_name = []
      end

      # Consumes a possible combined formatted, which is a template variable
      # followed by two underscores, and a formatter name.
      def consume_combined_formatter(chr)
        if chr == DELIM
          unexpected_token(chr) if @tmp.empty?
          @template_options = {
            format: @tmp.join.strip
          }

          commit_template
          @tmp = []
          transition STATE_LITERAL
          return
        end

        @tmp.push(chr)
      end

      # Consumes a conditional expression until a right paren is found. Raises
      # and error in case the expression is empty.
      def consume_cond_expr(chr)
        if chr == RPAREN
          unexpected_token(chr) if @template_name.empty?
          transition STATE_TEMPLATE_CONDITIONAL_EXPRESSION_END
          return
        end

        unexpected_token(chr) if !valid_name_char?(chr) && chr != DOT
        @template_name.push(chr)
      end

      # Initialises a Conditional in case the character is not a delimiter. The
      # latter will raise an unexpected token error if found.
      def consume_cond_expr_end(chr)
        unexpected_token(chr) unless chr == DELIM
        prepare_conditional
        transition STATE_LITERAL
      end

      # Consumes an option name until an equal sign (=) is found, requiring a
      # double-quote to follow it.
      def consume_option_name(chr)
        return transition(STATE_TEMPLATE_OPTION_VALUE_BEGIN) if chr == EQUALS

        if chr == DELIM
          unexpected_token(DELIM) if @template_name.empty?
          commit_template
          return transition STATE_LITERAL
        end

        @option_name.push(chr)
      end

      # Forces the value being parsed to be either a space or a double-quote.
      # Raises an unexected token error in case either condition is not met.
      def consume_option_value_begin(chr)
        return if space?(chr)
        return transition(STATE_TEMPLATE_OPTION_VALUE) if chr == QUOT

        unexpected_token(chr)
      end

      # Consumes an option value until a double-quote is reached.
      def consume_option_value(chr)
        if @last_chr != ESCAPE && chr == QUOT
          transition STATE_TEMPLATE_OPTION_OR_END
          return commit_template_option
        elsif @last_chr == ESCAPE && chr == QUOT
          @option_value.pop
        end

        @option_value.push(chr)
      end

      # Either consumes another template option, or reaches the end of a
      # template value. Raises an error in case the character isn't a commad,
      # space, or delimiter.
      def consume_option_or_end(chr)
        return if space? chr
        return transition(STATE_TEMPLATE_OPTION_NAME) if chr == COMMA

        if chr == DELIM
          transition STATE_LITERAL
          return commit_template
        end

        unexpected_token(chr)
      end
    end
  end
end
