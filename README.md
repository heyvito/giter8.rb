# Giter8.rb

go-giter8 implements [giter8](https://github.com/foundweekends/giter8)
parsing and rendering for both single templates and directory structures.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'giter8'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install giter8

## Usage

### Rendering a single template

In order to render a single template, both a template string and a set of
properties must be provided:

```ruby
require "giter8"

template_string = <<~EOF
Hi there, $name; format="capitalize"$!
EOF

props = Giter8.parse_props({
    name: "fefo"
})

puts Giter8.render_template(template, props)

# => "Hi there, Fefo!"
```

### Rendering a directory

Rendering a directory requries a source directory, a destination, and a set of
properties. Rendering directories also applies templates to file and directory
names. For instance, take the following structure from [spec/samples/structure](spec/samples/structure):

```
structure
├── README.md
├── default.properties
├── foo
│   └── $project_name__normalize$.c
└── header.h
```

Rendering it takes a single `Giter8` call:

```ruby
require "giter8"

props = { project_name: "giter8.rb" }
Giter8.render_directory("/path/to/spec/samples/structure", "/tmp/destination", props)
```

The following structure will exist at `/tmp/destination`:

```
output
├── README.md
├── foo
│   └── giter8.rb.c
└── header.h
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/heyvito/giter8.rb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/heyvito/giter8.rb/blob/master/CODE_OF_CONDUCT.md).

## Code of Conduct

Everyone interacting in the Giter8 project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/heyvito/giter8.rb/blob/master/CODE_OF_CONDUCT.md).

## License

```
The MIT License (MIT)

Copyright (c) 2021 Victor Gama de Oliveira

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```
