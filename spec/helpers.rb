# frozen_string_literal: true

module Helpers
  def sample_file(name)
    File.open("./spec/samples/#{name}.txt")
  end

  def output_path(file = "")
    File.join("./spec/samples/output", file)
  end
end
