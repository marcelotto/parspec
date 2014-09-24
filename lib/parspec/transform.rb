module Parspec
  class Transform < Parslet::Transform

    rule(status: simple(:status)) { status == 'OK' }
    rule(string: simple(:string)) do
      string.to_s.gsub(
          /\\["\/\\]/,
          '\\"' => '"',
          "\\\\" => "\\"
      )
    end

    rule(input: simple(:input), validity: simple(:valid)) do <<RSPEC_TEMPLATE
    it { should#{ valid ? '' : '_not' } parse '#{input.gsub("'", "\\''")}' }
RSPEC_TEMPLATE
    end

    rule(input: simple(:input), output: simple(:output)) do <<RSPEC_TEMPLATE
    it "should parse '#{input.gsub('"', '\\"')}' to #{output.gsub('"', '\\"')}" do
      expect(subject.parse('#{input.gsub("'", "\\''")}')).to eq #{output}
    end
RSPEC_TEMPLATE
    end

    rule(rule_name: simple(:rule_name), examples: sequence(:examples)) do <<RSPEC_TEMPLATE
  context '#{rule_name} parsing' do
    subject { parser.#{rule_name} }

#{examples.join("\n")}
  end
RSPEC_TEMPLATE
    end

    rule(spec_name: simple(:spec_name), rules: sequence(:rules)) do <<RSPEC_TEMPLATE
describe #{spec_name} do
  let(:parser) { #{spec_name}.new }

#{rules.join("\n")}
end
RSPEC_TEMPLATE
    end

  end
end
