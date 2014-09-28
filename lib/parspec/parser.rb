module Parspec
  class Parser < Parslet::Parser
    rule(:eof)        { any.absent? }
    rule(:newline)    { match['\n'].repeat(1) | eof }
    rule(:newline?)   { newline.maybe }
    rule(:space)      { match[' \t'].repeat(1) }
    rule(:space?)     { space.maybe }

    rule(:comment)    { str('#') >> (newline.absent? >> any).repeat >> newline }
    rule(:comment?)   { comment.maybe }

    rule(:newline_or_comment)  { newline | comment }
    rule(:newline_or_comment?) { newline_or_comment.maybe }

    rule(:special)         { match['"\\\\'] }
    #rule(:escaped_special) { str("\\") >> match['"\\\\'] }
    #rule(:special)         { match['\t\n\r"\\\\'] }
    rule(:escaped_special) { str("\\") >> match['tnr"\\\\'] }

    rule(:rule_name) do
      match['A-Za-z_'] >> match['\w'].repeat >> match['!?'].maybe
    end

    rule(:string) do
      str('"') >>
      ((escaped_special | special.absent? >> any).repeat).as(:string) >>
      str('"') >> space?
    end

    rule(:validity) { (str('OK') | str('FAIL')).as(:status) >> space? }
    rule(:validity_example) do
      string.as(:input) >> validity.as(:validity)
    end

    rule(:tree_example) do
      string.as(:input) >>
      (newline_or_comment >> space?).maybe >>
      str('->') >> space? >>
      (newline_or_comment >> space?).maybe >>
      string.as(:output)
    end

    rule(:include_example) do
      str('include') >> space >> rule_name.as(:include_rule)
    end

    rule(:description_example)  do
      (validity_example | tree_example | include_example) >> newline_or_comment
    end

    rule(:description_examples) do
      (space? >> (comment | description_example)).repeat
    end

    rule(:rule_description) do
      rule_name.as(:rule_name) >>
      str(':') >> space? >> newline_or_comment >>
      description_examples.as(:examples)
    end

    rule(:rule_descriptions) { rule_description.repeat }

    rule(:spec) do
      (str('parser') | str('transformer')).as(:type) >> space >>
      (newline.absent? >> any).repeat.as(:subject_class) >> newline_or_comment.repeat >>
      rule_descriptions.as(:rules)
    end

    root :spec
  end
end
