# frozen_string_literal: true

RSpec.describe Giter8::Parsers::PairsParser do
  it "correctly parses input" do
    data = File.read("./spec/samples/props.txt")
    result = subject.parse(data)

    expectation = {
      name: "Project Name",
      nameUpperSnake: "$name;format=\"upper,snake\"$",
      normalized: "$name;format=\"normalize\"$",
      organization: "com.foo",
      package: "$normalized;format=\"word\"$",
      minimumCoverage: "10",
      descriptions: "Project descriptions",
      namespace: "foo",
      productionCluster: "production",
      "dashed-variable" => "value"
    }
    expect(result.to_h).to eq expectation
  end
end
