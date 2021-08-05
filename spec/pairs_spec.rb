# frozen_string_literal: true

RSpec.describe Giter8::Pairs do
  let(:props) { { a: "x", b: "y", c: "z" } }
  subject { Giter8::Pairs.new(props) }

  it "finds a value" do
    expect(subject.find(:a)).to eq "x"
    expect(subject.find(:d)).to be_nil
  end

  it "finds a pair" do
    expect(subject.find_pair(:a)).to eq Giter8::Pair.new(:a, "x")
    expect(subject.find_pair(:a)).to eq({ a: "x" })
    expect(subject.find_pair(:d)).to be_nil
  end

  it "converts to a hash" do
    expectation = {
      a: "x",
      b: "y",
      c: "z"
    }
    expect(subject.to_h).to eq expectation
  end

  it "merges a hash into itself" do
    merge = {
      a: "a",
      d: "d"
    }
    subject.merge merge
    expect(subject.find(:a)).to eq "a"
    expect(subject.find(:d)).to eq "d"
  end
end
