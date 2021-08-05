# frozen_string_literal: true

require "forwardable"
require "stringio"
require "fileutils"

require_relative "giter8/version"
require_relative "giter8/error"
require_relative "giter8/pair"
require_relative "giter8/pairs"
require_relative "giter8/literal"
require_relative "giter8/template"
require_relative "giter8/conditional"
require_relative "giter8/ast"

require_relative "giter8/parsers/pairs_parser"
require_relative "giter8/parsers/template_parser"

require_relative "giter8/renderer/utils"
require_relative "giter8/renderer/executor"

require_relative "giter8/fs/fs"

require "ptools"

# Giter8 implements a parser and renderer for Giter8 templates
module Giter8
  # Parses a given String, Hash or File into a Pairs set. When parsing from a
  # File object, file metadata is used on error messages. The parser ignores
  # any content beginning with a hash (#) until the end of the line. Properties
  # are composed of a key comprised of a-z characters, numbers (0-9), unerscores
  # and dashes. When a file is passed, the caller is responsible for closing it.
  def self.parse_props(props)
    return props if props.is_a? Pairs

    if [String, Hash, File].none? { |type| props.is_a? type }
      raise Giter8::Error, "parse_props can only be used with strings, hashes, and files. Got #{props.class.name}"
    end

    opts = {}
    if props.is_a? File
      opts[:source] = props.path
      props = props.read
    end
    return Parsers::PairsParser.parse(props, opts) if props.is_a? String

    Pairs.new(props)
  end

  # Parses a provided Giter8 template from a String or File. When a File is
  # provided, its name will be used in error metadata. Also, when using a File
  # object, the caller is responsible for closing it.
  # Returns an AST object containing the file's contents.
  def self.parse_template(template)
    if [String, File, AST].none? { |type| template.is_a? type }
      raise Giter8::Error, "parse_template can only be used with strings and files. Got #{template.class.name}"
    end

    return template if template.is_a? AST

    opts = {}
    if template.is_a? File
      opts[:source] = template.path
      template = template.read
    end

    Parsers::TemplateParser.parse(template, opts)
  end

  # Renders a given template using a set of props. Template may be a
  # String or File, while props can be a Hash, String, or File. When providing
  # a File to either parameter, the caller is responsible for closing it.
  # Returns a string containing the rendered contents.
  def self.render_template(template, props)
    template = parse_template template
    props = parse_props props

    executor = Renderer::Executor.new(props)
    executor.exec(template)
  end

  # Renders a provided input directory into an output directory using a provided
  # props set.
  def self.render_directory(props, input, output)
    raise Giter8::Error, "Input directory #{input} does not exist" unless File.exist?(input)
    raise Giter8::Error, "Input path #{input} is not a directory" unless File.stat(input).directory?
    raise Giter8::Error, "Destination path #{output} already exists" if File.exist?(output)

    FS.render(props, input, output)
  end
end
