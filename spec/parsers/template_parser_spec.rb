# frozen_string_literal: true

RSpec.describe Giter8::Parsers::TemplateParser do
  it "parses literals" do
    input = "This is basically a 'big' literal"
    result = subject.parse(input)
    expect(result.length).to eq 1
    item = result.first
    expect(item).to be_a(Giter8::Literal)
    expect(item.value).to eq input
  end

  it "parses a template" do
    input = "$simpleTemplate$"
    result = subject.parse(input)
    expect(result.length).to eq 1
    item = result.first
    expect(item).to be_a(Giter8::Template)
    expect(item.name).to eq "simpleTemplate"
  end

  it "parses a template with options" do
    input = '$simpleTemplate; format="test, foo, bar", foo = "bar"$'
    result = subject.parse input
    expect(result.length).to eq 1

    item = result.first
    expect(item).to be_a(Giter8::Template)
    expect(item.name).to eq "simpleTemplate"
    expect(item.options).to eq({
                                 format: "test, foo, bar",
                                 foo: "bar"
                               })
  end

  it "handles broken templates" do
    input = "hello, $world;foo=\"\n$\""
    expect { subject.parse input }.to raise_error(Giter8::Error, "Unexpected EOF at unknown:2:2")
  end

  it "handles escapes" do
    input = "hello, \\$world $foo;foo=\"\\\"<-quote\"$\""
    result = subject.parse(input)
    expect(result.length).to eq 3

    # First item
    item = result[0]
    expect(item).to be_a(Giter8::Literal)
    expect(item.value).to eq "hello, $world "

    # Second item
    item = result[1]
    expect(item).to be_a(Giter8::Template)
    expect(item.name).to eq "foo"
    expect(item.options).to eq({ foo: '"<-quote' })

    # Third item
    item = result[2]
    expect(item).to be_a(Giter8::Literal)
    expect(item.value).to eq '"'
  end

  it "handles escapes, part 2" do
    input = "RUN echo \"\\${SSH_PRIVATE_KEY}\" > /root/.ssh/id_rsa"
    output = "RUN echo \"${SSH_PRIVATE_KEY}\" > /root/.ssh/id_rsa"
    result = subject.parse(input)
    expect(result.length).to eq 1

    item = result.first
    expect(item).to be_a(Giter8::Literal)
    expect(item.value).to eq output
  end

  it "handles conditionals" do
    input = "$if(foobar.truthy)$foo$endif$"
    result = subject.parse(input)
    expect(result.length).to eq 1

    item = result.first
    expect(item).to be_a(Giter8::Conditional)
    expect(item.property).to eq "foobar"
    expect(item.helper).to eq "truthy"
    expect(item.parent).to be_nil
    expect(item.cond_else_if).to be_empty
    expect(item.cond_else).to be_empty

    then_branch = item.cond_then
    expect(then_branch.length).to be 1
    then_item = then_branch.first
    expect(then_item).to be_a(Giter8::Literal)
    expect(then_item.value).to eq "foo"
    expect(then_item.parent).to eq item
  end

  it "handles if-else" do
    input = "$if(foobar.truthy)$foo$else$bar$endif$"
    result = subject.parse(input)
    expect(result.length).to eq 1

    item = result.first
    expect(item).to be_a(Giter8::Conditional)
    expect(item.property).to eq "foobar"
    expect(item.helper).to eq "truthy"
    expect(item.parent).to be_nil
    expect(item.cond_else_if).to be_empty

    then_branch = item.cond_then
    expect(then_branch.length).to be 1
    then_item = then_branch.first
    expect(then_item).to be_a(Giter8::Literal)
    expect(then_item.value).to eq "foo"
    expect(then_item.parent).to eq item

    else_branch = item.cond_else
    expect(else_branch.length).to be 1
    else_item = else_branch.first
    expect(else_item).to be_a(Giter8::Literal)
    expect(else_item.value).to eq "bar"
    expect(else_item.parent).to eq item
  end

  it "handles if-elseif" do
    result = subject.parse(<<~TEMPLATE)
      $if(foobar.truthy)$
      foo
      $elseif(foobar.truthy)$
      bar
      $endif$
      baz
    TEMPLATE

    expect(result.length).to eq 2
    item = result.first
    expect(item).to be_a(Giter8::Conditional)
    expect(item.property).to eq "foobar"
    expect(item.helper).to eq "truthy"
    expect(item.parent).to be_nil
    expect(item.cond_else).to be_empty

    then_branch = item.cond_then
    expect(then_branch.length).to be 1
    then_item = then_branch.first
    expect(then_item).to be_a(Giter8::Literal)
    expect(then_item.value).to eq "foo\n"
    expect(then_item.parent).to eq item

    else_if_branch = item.cond_else_if
    expect(else_if_branch.length).to be 1
    else_if_item = else_if_branch.first
    expect(else_if_item).to be_a(Giter8::Conditional)
    expect(else_if_item.property).to eq "foobar"
    expect(else_if_item.helper).to eq "truthy"
    expect(else_if_item.parent).to eq item
    expect(else_if_item.cond_else).to be_empty
    expect(else_if_item.cond_else_if).to be_empty
    expect(else_if_item.cond_then).to_not be_empty
    expect(else_if_item.cond_then.first).to be_a(Giter8::Literal)
    expect(else_if_item.cond_then.first.value).to eq "bar\n"

    last_item = result.last
    expect(last_item).to be_a(Giter8::Literal)
    expect(last_item.value).to eq "baz\n"
  end

  it "handles if-elseif-else" do
    result = subject.parse(<<~TEMPLATE)
      $if(foobar.truthy)$
      foo
      $elseif(foobar.truthy)$
      bar
      $else$
      bax
      $endif$
      baz
    TEMPLATE

    expect(result.length).to eq 2
    item = result.first
    expect(item).to be_a(Giter8::Conditional)
    expect(item.property).to eq "foobar"
    expect(item.helper).to eq "truthy"
    expect(item.parent).to be_nil

    then_branch = item.cond_then
    expect(then_branch.length).to be 1
    then_item = then_branch.first
    expect(then_item).to be_a(Giter8::Literal)
    expect(then_item.value).to eq "foo\n"
    expect(then_item.parent).to eq item

    else_if_branch = item.cond_else_if
    expect(else_if_branch.length).to be 1
    else_if_item = else_if_branch.first
    expect(else_if_item).to be_a(Giter8::Conditional)
    expect(else_if_item.property).to eq "foobar"
    expect(else_if_item.helper).to eq "truthy"
    expect(else_if_item.parent).to eq item
    expect(else_if_item.cond_else).to be_empty
    expect(else_if_item.cond_else_if).to be_empty
    expect(else_if_item.cond_then).to_not be_empty
    expect(else_if_item.cond_then.first).to be_a(Giter8::Literal)
    expect(else_if_item.cond_then.first.value).to eq "bar\n"

    else_branch = item.cond_else
    expect(else_branch.length).to be 1
    expect(else_branch.first).to be_a Giter8::Literal
    expect(else_branch.first.value).to eq "bax\n"

    last_item = result.last
    expect(last_item).to be_a(Giter8::Literal)
    expect(last_item.value).to eq "baz\n"
  end

  it "raises an error on unordered conditionals" do
    input = <<~TEMPLATE
      $if(foobar.truthy)$
      foo
      $else$
      bar
      $elseif(foobar.truthy)$
      baz
      $endif$
    TEMPLATE

    error_message = "Unexpected keyword `elseif' at unknown:5:7"
    expect { subject.parse(input) }.to raise_error(Giter8::Error, error_message)
  end

  it "handles composite formatting" do
    result = subject.parse("$name__decap$")

    expect(result.length).to eq 1
    item = result.first
    expect(item).to be_a(Giter8::Template)
    expect(item.name).to eq "name"
    expect(item.options).to eq({ format: "decap" })
  end

  it "handles dashed property names" do
    result = subject.parse("$some-variable$")
    expect(result.length).to eq 1
    item = result.first
    expect(item).to be_a(Giter8::Template)
    expect(item.name).to eq "some-variable"
    expect(item.options).to be_empty
  end

  it "detects pure literals" do
    result = subject.parse("A pure-literal \\$value")
    expect(result.length).to eq 1
    item = result.first
    expect(item).to be_a(Giter8::Literal)
    expect(item.value).to eq "A pure-literal $value"
  end
end
