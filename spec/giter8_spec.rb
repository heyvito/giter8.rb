# frozen_string_literal: true

RSpec.describe Giter8 do
  subject { Giter8 }
  it "has a version number" do
    expect(Giter8::VERSION).not_to be nil
  end

  it "renders contents as expected" do
    file = sample_file("rendering")
    res = Giter8.render_template(file, { ok: "yes", notok: "no" })
    expect(res).to eq "OK!\n"
  end

  it "handles nested conditionals" do
    file = sample_file("nested_conditionals")
    res = Giter8.render_template(file, { parent: "false", child: "true" })
    expect(res).to eq ""
  end

  it "handles absent conditional properties" do
    file = sample_file("absent_cond_prop")
    res = Giter8.render_template(file, { existing: "true" })
    expect(res).to eq "Yay!\n"
  end

  it "handles presence-based conditionals" do
    file = sample_file("present_cond_prop")
    res = Giter8.render_template(file, { existing: "foobar" })
    expect(res).to eq "foobar\n"
  end
end
