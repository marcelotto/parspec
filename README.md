# Parspec

A [gUnit](https://theantlrguy.atlassian.net/wiki/display/ANTLR3/gUnit+-+Grammar+Unit+Testing)-like specification language for [Parslet](http://kschiess.github.io/parslet/) parsers and transformers, which translates to [RSpec](http://rspec.info/).


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'parspec', group: :test
```

And then execute:

    $ bundle

Or install with gem:

    $ gem install parspec


## Specification language

### Example

The following example shows parts of the [TOML spec](https://github.com/zerowidth/toml-parslet/blob/master/spec/toml/parser_spec.rb) translated to Parspec:

    parser TOML::Parser
    
    value:
        "120381" OK
        "0181" FAIL
        "3.14159" OK
        ".1" FAIL
        "true" OK
        "truefalse" FAIL
        "1979-05-27T07:32:00Z" OK
        "1979l05-27 07:32:00" FAIL
        "\"hello world\"" OK
        "\"hello\nworld\"" FAIL
        "\"hello/world\"" FAIL
    
        "1234"                 -> ":integer => '1234'"
        "-0.123"               -> ":float   => '-0.123'"
        "true"                 -> ":boolean => 'true'"
        "1979-05-27T07:32:00Z" -> ":datetime => '1979-05-27T07:32:00Z'"
        "\"hello world\""      -> ":string => 'hello world'"
        "\"hello\nworld\""     -> ":string => \"hello\nworld\""
    
    array:
        "[]" OK
        "[1]" OK
        "[0.1, -0.1, 3.14159]" OK
        "[ true, false, true, true ]" OK
        "[1979-05-27T07:32:00Z]" OK  # [2013-02-24T17:26:21Z]
        "[\n1\n,\n2\n]" OK
        "[\n\n\t1  , 2,     3\\t,4\n]" OK
        "[1, 2, \"three\"]" FAIL
        "[1,2,]" OK
        "[1,2\n,\\t]" OK
    
         "[1,2]"     -> ":array => [ {:integer => '1'}, {:integer => '2'}]"
         "[]"        -> ":array => '[]'"
         "[ [1,2] ]"
            -> ":array => [
                  {:array => [ {:integer => '1'}, {:integer => '2'}]}
               ]"
    
    key:
         "foobar" OK
         "lolwhat.noWAY" OK
         "no white\\tspace" FAIL
         "noequal=thing" FAIL
    
    assignment:
          "key=3.14" OK
          "key = 10" OK
          "key = true" OK
          "key = \"value\"" OK
          "#comment=1" FAIL
          "thing = 1" -> ":key => 'thing', :value => {:integer => '1'}"


### Description

#### Header

A Parspec specification starts with a definition of the subject:

    <type> <instantiation expression>

There are two types of specifications: `parser` and `transformer`. A parser specification describes a `Parslet::Parser`, a transformer specification describes a `Parslet::Transform`. Syntactically these types of specifications are equal, but the generated RSpec descriptions will differ.

The instantiation expression is used to create a RSpec test subject. It usually consists of a constant for a `Parslet::Parser` or `Parslet::Transform` class, according to the type of specification, but can be any valid Ruby expression, which responds to `new` with a `Parslet::Parser` or `Parslet::Tranform` instance.


#### Rule examples

After the definition, a series of examples for the grammar rules follows. Rules start with a rule name followed by a colon.

There are two types of examples: simple validations and mapping examples.


##### Validations

A validation is a string in double-quotes followed either by the keyword `OK` or `FAIL`, according to the expected outcome of parsing the given string under the given rule. Currently, it is supported in parser specifications only.

For example, the following validation:

    some_rule:
      "some input" OK
      "another input" FAIL

will translate to this RSpec description:

```ruby
context 'some_rule parsing' do
  subject { parser.some_rule }

  it { should parse 'some input' }
  it { should_not parse 'another input' }
end
```


##### Mapping examples

Mapping examples describe the input-output-behaviour of a rule. Syntactically they consist of two strings separated by `->`. Since the semantics of parser and transformer specifications differ, let's discuss them separately, starting with the parser case:

While the input string on the left side is simply some sample text as in a validity example, the output string on the right must contain a valid Ruby expression, which should evaluate to the expected outcome of the respective rule parsing.

For example, the following mapping:

    some_rule:
      "some input"    -> "42"
      "another input" -> "{ foo: 'bar' }"

will be translated to the following RSpec parser specification:

```ruby
context 'some_rule parsing' do
  subject { parser.some_rule }

  it "should parse 'some input' to 42" do
    expect(subject.parse('some input')).to eq 42
  end

  it "should parse 'another input' to { foo: 'bar' }" do
    expect(subject.parse('another input')).to eq { foo: 'bar' }
  end
end
```

In the case of a transformer specification, both sides must contain Ruby expressions.


#### Shared examples

The examples of a rule can be reused inside other rules with the `include` keyword:

    some_rule:
      "some input"    -> "42"
      "another input" -> "{ foo: 'bar' }"

    another_rule:
      include some_rule


#### String escaping

Parspec strings in general support the following escape sequences: `\t`, `\n`, `\r`, `\"`, `\\`. 
  

#### Comments

One-line comments are supported in the `#`-style.


## Usage

### Command-line interface

Parspec comes with a command-line interface through the `parspec` command.

For a full description of the available parameters, run:

    $ parspec --help
    Usage: parspec [options] PARSPEC_FILE
        -h, --help                       Display this information
        -v, --version                    Print version information
        -s, --stdout                     Print the translation to stdout only
        -o, --out OUTPUT_FILE            Path where translated RSpec file should be stored
        -b, --beside-input               Put the output file into the same directory as the input
        -e, --header HEADER              A block of code to be put in front of the translation
            --no-debug-parse             Don't print the whole Parslet ascii_tree on errors

Unless specified otherwise, the default header is:

```ruby
# coding: utf-8
require 'spec_helper'
require 'parslet/convenience'
require 'parslet/rig/rspec'
```


### `load_parspec` 

You can use the command-line interface to integrate Parspec in your testing tool chain, e.g. via Rake or Guard. 

But you can also load your Parspec spec from a normal Ruby file in your spec directory with the `load_parspec` command:   

```ruby
require 'spec_helper'
require 'parspec'
require 'my_parser'

load_parspec __FILE__
```

If the `load_parspec` command gets a filename with the extension `.rb`, it looks for a file with the same name, but the extension `.parspec`. For example, if the former Ruby file would be at `spec/my_parser/my_parser_spec.rb`, the `load_parspec` command would try to load a Parspec spec from a file `spec/my_parser/my_parser_spec.parspec`.


Note: This feature is currently implemented via `eval`, till I find a way to include specs from other RSpec files or another alternative. If you have any advice, please share it in issue #1.


## Contributing

1. Fork it ( https://github.com/marcelotto/parspec/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Author

- Marcel Otto
