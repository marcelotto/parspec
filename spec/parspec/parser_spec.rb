require 'spec_helper'
require 'parslet/rig/rspec'

describe Parspec::Parser do
  let(:parser) { Parspec::Parser.new }

  context 'string parsing' do
    let(:string_parser) { parser.string }
    subject { string_parser }
    it { should parse('"test"')}
    it { should parse("\"test\n on multiple lines\"")}

    it { should_not parse('test')}

    it 'should interpret the empty string correctly' do
      expect(string_parser.parse('""')).to eq string: [] # TODO: should be ''
    end

    it 'should preserve escaped double-quotes' do
      expect(string_parser.parse('"\\"test\\""')).to eq string: '\\"test\\"'
    end

    it 'should preserve escape-sequences' do
      expect(string_parser.parse('"\\n"')).to eq string: '\n'
    end

    it 'should preserve special characters' do
      expect(string_parser.parse("\"test with:\n\tspecial characters\n\tesp. \\\", \\\\\""))
        .to eq string: "test with:\n\tspecial characters\n\tesp. \\\", \\\\"
    end
  end

  context 'validity example parsing' do
    let(:validity_example_parser) { parser.validity_example }
    subject { validity_example_parser }
    it { should parse('"test" OK') }
    it { should parse('"test" ok') }
    it { should parse('"test" FAIL') }
    it { should parse('"test" Fail') }
    it { should parse("\"test\n on multiple lines\" OK") }

    it { should_not parse('"test"') }
    it { should_not parse('"test" OTHER') }
    it { should_not parse('"test" -> OTHER') }

    it 'should be parsed to {input: {string: "example"}, validity: {status: "OK"}}, when validity is OK' do
      expect(validity_example_parser.parse('"test" OK'))
        .to eq input: { string: 'test' }, validity: {status: 'OK'}
      expect(validity_example_parser.parse('"test" OK    '))
      .to eq input: { string: 'test' }, validity: {status: 'OK'}
    end

    it 'should be parsed to {input: {string: "example"}, validity: {status: "FAIL"}}, when validity is FAIL' do
      expect(validity_example_parser.parse('"test" FAIL'))
        .to eq input: { string: 'test' }, validity: {status: 'FAIL'}
    end
   end

  context 'mapping example parsing' do
    let(:mapping_example_parser) { parser.mapping_example }
    subject { mapping_example_parser }
    it { should parse('"test" -> ":foo => :bar"') }
    it { should parse('"test" -> "{ foo: 42, bar: \'baz\'} "') }
    it { should parse("\"test\n on multiple lines\" -> \"{\n\tfoo: 42,\tbar: 'baz'\n}\"") }

    it { should_not parse('"test"') }
    it { should_not parse('"test" OK') }
    it { should_not parse('"test" -> OK') }

    it 'should be parsed to {input: {string: "example"}, output: {string: "example"}}' do
      expect(mapping_example_parser.parse('"test" -> ":foo => :bar"'))
        .to eq input: { string: 'test' }, output: { string: ':foo => :bar' }
      expect(mapping_example_parser.parse('"test" -> "{ foo: 42, bar: \'baz\'} "'))
        .to eq input: { string: 'test' }, output: { string: "{ foo: 42, bar: 'baz'} " }
      expect(mapping_example_parser.parse("\"test\n on multiple lines\" -> \"{\n\tfoo: 42,\tbar: 'baz'\n}\""))
        .to eq input: { string: "test\n on multiple lines" }, output: { string: "{\n\tfoo: 42,\tbar: 'baz'\n}" }
    end
  end

  context 'rule name parsing' do
    let(:rule_name_parser) { parser.rule_name }
    subject { rule_name_parser }
    it { should parse 'a_rule_name' }
    it { should parse 'rule1' }
    it { should parse '_rule2' }
    it { should parse 'a_rule_name?' }
    it { should parse 'a_rule_name!' }
    it { should_not parse '0a' }
  end

  context 'rule description parsing' do
    let(:rule_description_parser) { parser.rule_description }
    subject { rule_description_parser }

    it { should parse "a_rule_name:\n" }
    it { should parse "a_rule_name:\n\"test\" OK" }
    it { should parse <<PARSPEC_RULE_DESCRIPTION
a_rule_name:
"test" -> "foo: :bar"
PARSPEC_RULE_DESCRIPTION
    }

    it { should parse <<PARSPEC_RULE_DESCRIPTION
a_rule_name:
"test" OK
"test" -> "foo: :bar"
PARSPEC_RULE_DESCRIPTION
    }

    it { should parse <<PARSPEC_RULE_DESCRIPTION
a_rule_name:
  "test" OK
  "test" -> "foo: :bar"
PARSPEC_RULE_DESCRIPTION
    }

    it { should parse <<PARSPEC_RULE_DESCRIPTION
a_rule_name:

  "test" OK

  "test" -> "foo: :bar"


PARSPEC_RULE_DESCRIPTION
    }

    it { should parse <<PARSPEC_RULE_DESCRIPTION
a_rule_name:
  "test"
    -> "foo: :bar"
  "test" ->
      "foo: :bar"

  "test"
    ->
    "foo: :bar"
PARSPEC_RULE_DESCRIPTION
    }

    it { should parse <<PARSPEC_RULE_DESCRIPTION
a_rule_name:
#  "test" OK
PARSPEC_RULE_DESCRIPTION
    }

    it { should parse <<PARSPEC_RULE_DESCRIPTION
a_rule_name:
  "test" OK
#  "test" -> "foo: :bar"
PARSPEC_RULE_DESCRIPTION
    }

    it { should parse <<PARSPEC_RULE_DESCRIPTION
a_rule_name: # this a comment
  "test" OK
PARSPEC_RULE_DESCRIPTION
    }

    it { should parse <<PARSPEC_RULE_DESCRIPTION
a_rule_name:
  "test" OK             # this is a comment
PARSPEC_RULE_DESCRIPTION
    }


    it { should parse <<PARSPEC_RULE_DESCRIPTION
a_rule_name: # comment #1

# comment #2

# comment #3

  "test" OK  # comment #4

# comment #5


  "test" -> "foo: :bar" # comment #6
# comment #7

PARSPEC_RULE_DESCRIPTION
    }

    it 'should parse a rule without examples to {rule_name: "name", examples: []}' do
      expect(rule_description_parser.parse("a_rule_name:\n#some comment\n\n"))
        .to eq rule_name: 'a_rule_name', examples: []
    end

    it 'should be parsed to {rule_name: "name", examples: [...]}' do
      tree = {
          rule_name: 'a_rule_name',
          examples: [
            {input: {string: 'test'}, validity: {status: 'OK' }},
            {input: {string: 'test'}, output: {string: 'foo: :bar'}}
          ]
      }

      expect(rule_description_parser.parse(<<PARSPEC_RULE_DESCRIPTION
a_rule_name:
"test" OK
"test" -> "foo: :bar"
PARSPEC_RULE_DESCRIPTION
      )).to eq tree

      expect(rule_description_parser.parse(<<PARSPEC_RULE_DESCRIPTION
a_rule_name:

  "test" OK

  "test" -> "foo: :bar"


PARSPEC_RULE_DESCRIPTION
       )).to eq tree

      expect(rule_description_parser.parse(<<PARSPEC_RULE_DESCRIPTION
a_rule_name: # comment #1

# comment #2

# comment #3

  "test" OK  # comment #4

# comment #5


  "test" -> "foo: :bar" # comment #6
# comment #7

PARSPEC_RULE_DESCRIPTION
             )).to eq tree
    end

  end

  context 'spec parsing' do
    it { should parse '' }
    it { should parse ' ' }
    it { should parse "\n" }
    it { should parse "\n# comment only\n" }
    it { should parse 'parser Some::Parser' }
    it { should parse ' parser Some::Parser' }

    it { should parse <<PARSPEC
parser Some::Parser

rule1:
  "test" OK
  "test" -> "foo: :bar"

rule2:
  "foo" OK
  "foo" -> ":bar => :foo"
PARSPEC
    }

    it { should parse <<PARSPEC
parser Some::Parser # a comment

rule1:
  "test" OK
  "test" -> "foo: :bar"
PARSPEC
    }

    it { should parse <<PARSPEC
 parser Some::Parser
# a comment
rule1:
  "test" OK
  "test" -> "foo: :bar"
PARSPEC
    }

    it { should parse <<PARSPEC
# a comment
parser Some::Parser

 # a comment

rule1:
  "test" OK
  "test" -> "foo: :bar"
PARSPEC
    }

    it 'should be parsed to {spec_name: "name", rules: [...]}' do
      tree = {
          header: {
              subject_class: 'Some::Parser',
              type: 'parser'
          },
          rules: [
            { rule_name: 'rule1',
              examples: [
                  {input: {string: 'test'}, validity: {status: 'OK' }},
                  {input: {string: 'test'}, output: {string: 'foo: :bar'}}
              ] },
            { rule_name: 'rule2',
              examples: [
                  {input: {string: 'foo'}, output: {string: ':bar => :foo'}}
              ] }
          ]
      }

      expect(parser.parse(<<PARSPEC
parser Some::Parser

rule1:
  "test" OK
  "test" -> "foo: :bar"

rule2:
  "foo" -> ":bar => :foo"
PARSPEC

             )).to eq tree
    end

  end

end
