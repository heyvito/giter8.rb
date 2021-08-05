# frozen_string_literal: true

RSpec.describe Giter8::FS do
  it "rejects files based on patterns" do
    files = {
      "hello/foo/bar.c" => false,
      "file.css" => true,
      "foo/bar.css" => true,
      "a/longer/path/to/file.html" => true,
      "something.go" => false,
      "foobar.xml" => true,
      "other.xml" => false,
      "/something/test/foo/bar.c" => true
    }

    patterns = %w[*.css *.html foobar.xml */test/foo/bar.c]

    files.each_pair do |k, verbatim|
      raise "#{k} should be verbatim" if Giter8::FS.verbatim?(k, patterns) != verbatim
    end
  end

  it "should correctly render a directory" do
    output = File.absolute_path("./spec/samples/output")
    FileUtils.rm_rf(output) if File.exist? output

    props_file = File.open("./spec/samples/structure/default.properties")
    props = Giter8.parse_props(props_file)
    props_file.close

    Giter8.render_directory(props, "./spec/samples/structure", output)

    expect(File).to exist(output_path)
    expect(File).to exist(output_path("header.h"))
    expect(File).to exist(output_path("README.md"))
    expect(File).to exist(output_path("foo"))
    expect(File).to exist(output_path("foo/giter8.rb.c"))
  end
end
