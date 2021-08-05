# frozen_string_literal: true

module Giter8
  # FS implements filesystem-related methods for handling template directories
  class FS
    # Returns whether the provided path must be copied verbatim by the renderer
    # instead of being handled by parsers.
    def self.verbatim?(path, ignore_patterns)
      return false if ignore_patterns.empty?

      ignore_patterns.any? do |pattern|
        File.fnmatch? pattern, path
      end
    end

    # Returns whether a given path contains a binary file.
    def self.binary?(path)
      File.binary?(path)
    end

    # Recursively enumerate paths inside a given path and returns a list
    # of files, except "default.properties".
    def self.enumerate(path)
      original_path = path
      path = "#{path}/**/*" unless path.match?(%r{/\*})
      Dir.glob(path)
         .select { |e| File.stat(e).file? }
         .reject { |e| File.basename(e) == "default.properties" }
         .collect { |e| e[original_path.length + 1..] }
    end

    def self.handle_file_copy(from, to)
      FileUtils.cp(from, to)
    end

    def self.handle_file_render(props, source, destination)
      f = File.open(source)
      rendered = Giter8.render_template(f, props)
      f.close

      File.write(destination, rendered, 0, mode: "w")
    end

    # Optimistically attempt to render a file name. Returns the name verbatim
    # in case parsing or rendering fails.
    def self.render_file_name(name, props)
      ast = Giter8.parse_template(name)
      Giter8.render_template(ast, props)
    rescue Giter8::Error
      name
    end

    # Renders the contents of a given input directory into a destination,
    # creating directories as required, using provided opts to render templates.
    def self.render(props, input, output)
      FileUtils.mkdir_p output
      props = Giter8.parse_props(props)

      verbatim = []
      verbatim = props.fetch(:verbatim).split if props.key? :verbatim

      enumerate(input).each do |file|
        source = File.absolute_path(File.join(input, file))
        output_file_name = render_file_name(file, props)
        destination = File.absolute_path(File.join(output, output_file_name))
        FileUtils.mkdir_p File.dirname(destination)
        if verbatim?(source, verbatim)
          handle_file_copy(source, destination)
        else
          handle_file_render(props, source, destination)
        end
      end
    end
  end
end
