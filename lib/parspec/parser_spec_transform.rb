module Parspec
  class ParserSpecTransform < Parslet::Transform

    class << self
      attr_accessor :no_debug_parse
    end

    rule(input: simple(:input), validity: simple(:valid)) do <<RSPEC_TEMPLATE
    it { should#{ valid ? '' : '_not' } parse '#{input.gsub("'", "\\''")}' }
RSPEC_TEMPLATE
    end

    rule(input: simple(:input), output: simple(:output)) do <<RSPEC_TEMPLATE
    it "should parse '#{input.gsub('"', '\\"')}' to #{output.gsub('"', '\\"')}" do
      expect(subject.#{ParserSpecTransform.no_debug_parse ? 'parse' : 'parse_with_debug'}('#{input.gsub("'", "\\''")}')).to eq #{output}
    end
RSPEC_TEMPLATE
    end

    rule(include_rule: simple(:rule_name)) do <<RSPEC_TEMPLATE
    it_behaves_like 'every #{rule_name} parsing'
RSPEC_TEMPLATE
    end

    rule(rule_name: simple(:rule_name), examples: sequence(:examples)) do <<RSPEC_TEMPLATE
  shared_examples 'every #{rule_name} parsing' do

#{examples.join("\n")}
  end

  context '#{rule_name} parsing' do
    subject { parser.#{rule_name} }

    it_behaves_like 'every #{rule_name} parsing'
  end
RSPEC_TEMPLATE
    end

    rule(header: {type: simple(:type), subject_class: simple(:subject_class)},
         rules: sequence(:rules)) do <<RSPEC_TEMPLATE
describe #{subject_class} do
  let(:parser) { #{subject_class}.new }

#{rules.join("\n")}
end
RSPEC_TEMPLATE
    end

  end
end
