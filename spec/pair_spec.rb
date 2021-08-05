# frozen_string_literal: true

RSpec.describe Giter8::Pair do
  subject { Giter8::Pair }

  it "detects truthy values" do
    value = subject.new("anything", "y")
    expect(value).to be_truthy
  end
end
