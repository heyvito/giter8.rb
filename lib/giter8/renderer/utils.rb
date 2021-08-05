# frozen_string_literal: true

module Giter8
  # nodoc
  module Renderer
    WORD_ONLY_REGEXP = /[^a-zA-Z0-9_]/.freeze
    WORD_SPACE_REGEXP = /[^a-zA-Z0-9]/.freeze
    SNAKE_CASE_REGEXP = /[\s.]/.freeze
    ALPHABET = ((65..90).to_a + (97..122).to_a).map(&:chr).freeze

    def self.uppercase(val)
      val.upcase
    end

    def self.lowercase(val)
      val.downcase
    end

    def self.capitalize(val)
      val.capitalize
    end

    def self.decapitalize(val)
      lowercase(val)
    end

    def self.start_case(val)
      val.split.map(&:capitalize)
    end

    def self.word_only(val)
      val.gsub(WORD_ONLY_REGEXP, "")
    end

    def self.word_space(val)
      val.gsub(WORD_SPACE_REGEXP, " ")
    end

    def self.upper_camel(val)
      word_only(start_case(val))
    end

    def self.lower_camel(val)
      decapitalize(word_only(start_case(val)))
    end

    def self.hyphenate(val)
      val.gsub(/\s/, "-")
    end

    def self.normalize(val)
      lowercase(hyphenate(val))
    end

    def self.snake_case(val)
      val.gsub(SNAKE_CASE_REGEXP, "_")
    end

    def self.package_naming(val)
      val.gsub(/\s/, ".")
    end

    def self.package_dir(val)
      val.gsub(/\./, "/")
    end

    def self.random
      ALPHABET.sample(40).join
    end

    HELPERS = {
      "upper" => method(:uppercase),
      "uppercase" => method(:uppercase),
      "lower" => method(:lowercase),
      "lowercase" => method(:lowercase),
      "cap" => method(:capitalize),
      "capitalize" => method(:capitalize),
      "decap" => method(:decapitalize),
      "decapitalize" => method(:decapitalize),
      "start" => method(:start_case),
      "start-case" => method(:start_case),
      "word" => method(:word_only),
      "word-only" => method(:word_only),
      "space" => method(:word_space),
      "word-space" => method(:word_space),
      "Camel" => method(:upper_camel),
      "upper-camel" => method(:upper_camel),
      "camel" => method(:lower_camel),
      "lower-camel" => method(:lower_camel),
      "hyphen" => method(:hyphenate),
      "hyphenate" => method(:hyphenate),
      "norm" => method(:normalize),
      "normalize" => method(:normalize),
      "snake" => method(:snake_case),
      "snake-case" => method(:snake_case),
      "package" => method(:package_naming),
      "package-naming" => method(:package_naming),
      "packaged" => method(:package_dir),
      "package-dir" => method(:package_dir),
      "random" => method(:random),
      "generate-random" => method(:random)
    }.freeze
  end
end
