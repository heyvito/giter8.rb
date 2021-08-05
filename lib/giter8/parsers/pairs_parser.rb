# frozen_string_literal: true

module Giter8
  module Parsers
    # PairsParser implements an FSM for parsing a key-value string containing
    # property pairs for rendering.
    class PairsParser
      STATE_KEY     = 0
      STATE_VALUE   = 1
      STATE_COMMENT = 2

      CHR_SPACE           = " "
      CHR_TAB             = "\t"
      CHR_CARRIAGE_RETURN = "\r"
      CHR_NEWLINE         = "\n"
      CHR_HASH            = "#"
      CHR_EQUAL           = "="
      WHITE_CHARS = [CHR_SPACE, CHR_TAB, CHR_CARRIAGE_RETURN, CHR_NEWLINE].freeze
      ALPHA_REGEXP = /[[:alpha:]]/.freeze

      # Parses a given key-value pair list within a string with provided options.
      # Options is a hash that currently only supports the :source key, which
      # must be the name of the file being parsed. This key is used to identify
      # any errors whilst parsing the contents and will be provided on any
      # raised errors.
      # Returns an Pairs object with the read properties.
      def self.parse(input, opts = {})
        new(opts).parse(input)
      end

      # Initialises a new PairsParser instance.
      # See also: PairsParser.parse
      def initialize(opts = {})
        @pairs = []
        @state = STATE_KEY
        @tmp_key = []
        @tmp_val = []
        @source = opts[:source] || "unknown"
        @column = 0
        @line = 1
      end

      # Parses a given input string into key-value Pair objects.
      # Returns an Pairs object of identified keys and values.
      def parse(input)
        input.chars.each do |chr|
          chr = chr.chr
          case @state
          when STATE_KEY
            parse_key(chr)

          when STATE_COMMENT
            @state = STATE_KEY if chr == CHR_NEWLINE

          when STATE_VALUE
            parse_value(chr)
          end

          @column += 1
          if chr == CHR_NEWLINE
            @line += 1
            @column = 0
          end
        end

        finish_parse
      end

      private

      # Returns the current FSM's location as a string representation in the
      # format SOURCE_FILE_NAME:LINE:COLUMN
      def location
        "#{@source}:#{line}:#{column}"
      end

      # Parses a given character into the current key's key property.
      # Raises an error in case the character is not accepted as a valid
      # candidate for a key identifier.
      def parse_key(chr)
        if @tmp_key.empty? && WHITE_CHARS.include?(chr)
          nil
        elsif @tmp_key.empty? && chr == CHR_HASH
          @state = STATE_COMMENT
        elsif @tmp_key.empty? && !ALPHA_REGEXP.match?(chr)
          raise Giter8::Error, "unexpected char #{chr} at #{location}"
        elsif chr == CHR_EQUAL
          @state = STATE_VALUE
        else
          @tmp_key << chr
        end
      end

      # Consumes provided characters until a newline is reached.
      def parse_value(chr)
        if chr != CHR_NEWLINE
          @tmp_val << chr
          return
        end

        push_result
        @state = STATE_KEY
      end

      def reset_tmp
        @tmp_key = []
        @tmp_val = []
      end

      def push_result
        @pairs << Pair.new(@tmp_key.join.strip, @tmp_val.join.strip)
        reset_tmp
      end

      def finish_parse
        raise Giter8::Error, "unexpected end of input at #{location}" if @state == STATE_KEY && !@tmp_key.empty?

        push_result if @state == STATE_VALUE

        result = Pairs.new(@pairs)
        reset_tmp
        @state = STATE_KEY
        @pairs = []
        result
      end
    end
  end
end
