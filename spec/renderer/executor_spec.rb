# frozen_string_literal: true

RSpec.describe Giter8::Renderer::Executor do
  subject do
    pairs = Giter8::Pairs.new({ simpleTemplate: "FoO" })
    Giter8::Renderer::Executor.new(pairs)
  end

  let(:template) do
    Giter8.parse_template("$simpleTemplate; format=\"lower\"$").first
  end

  let(:alt_template) do
    template = "This points\n\nTo a n invalid template: $altTemplate; format=\"lower\"$"
    Giter8.parse_template(template).find { |e| e.is_a? Giter8::Template }
  end

  let(:invalid_formatter) do
    Giter8.parse_template("$simpleTemplate; format=\"invalid\"$").first
  end

  it "extracts format options" do
    result = subject.send(:extract_format_options, template)
    expect(result.length).to be 1
    expect(result.first).to eq "lower"
  end

  it "detects undefined variables" do
    error_message = "Property `altTemplate' is not defined at unknown:3:25"
    expect { subject.send(:run_methods, alt_template) }.to raise_error(Giter8::PropertyNotFoundError, error_message)
  end

  it "detects invalid formatters" do
    error_message = "Formatter `invalid' is not defined at unknown:1:0"
    expect do
      subject.send(:run_methods, invalid_formatter)
    end.to raise_error(Giter8::FormatterNotFoundError, error_message)
  end

  it "applies formatting" do
    result = subject.send(:run_methods, template)
    expect(result).to eq "foo"
  end
end
