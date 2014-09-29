module Parspec
  class TransformerSpecTransform < Parslet::Transform

    rule(input: simple(:input), validity: simple(:valid)) do
      raise NotImplementedError
    end

    rule(input: simple(:input), output: simple(:output)) do <<RSPEC_TEMPLATE
    it "should parse '#{input.gsub('"', '\\"')}' to #{output.gsub('"', '\\"')}" do
      expect(transformer.apply(#{input})).to eq #{output}
    end
RSPEC_TEMPLATE
    end

    rule(include_rule: simple(:rule_name)) do <<RSPEC_TEMPLATE
    it_behaves_like 'every #{rule_name} transformation'
RSPEC_TEMPLATE
    end

    rule(rule_name: simple(:rule_name), examples: sequence(:examples)) do <<RSPEC_TEMPLATE
  shared_examples 'every #{rule_name} transformation' do

#{examples.join("\n")}
  end

  context '#{rule_name} tranformation' do
    it_behaves_like 'every #{rule_name} transformation'
  end
RSPEC_TEMPLATE
    end

    rule(header: {type: simple(:type), subject_class: simple(:subject_class)},
         rules: sequence(:rules)) do <<RSPEC_TEMPLATE
describe #{subject_class} do
  let(:transformer) { #{subject_class}.new }

#{rules.join("\n")}
end
RSPEC_TEMPLATE
    end

  end
end
