module Parspec
  class Parser < Parslet::Parser
    rule(:eof)        { any.absent? }
    rule(:newline)    { match['\n'].repeat(1) | eof }
    rule(:newline?)   { newline.maybe }
    rule(:space)      { match[' \t'].repeat(1) }
    rule(:space?)     { space.maybe }

    rule(:comment)    { str('#') >> (newline.absent? >> any).repeat >> newline }
    rule(:comment?)   { comment.maybe }

    rule(:newline_or_comment) { newline | comment }
    rule(:newline_or_comment?) { newline_or_comment.maybe }

    rule(:special)         { match['"\\\\'] }
    rule(:escaped_special) { str('\\') >> match['"\\\\'] }
    #rule(:special) { match['\0\t\n\r"\\\\'] }
    #rule(:escaped_special) { str("\\") >> match['0tnr"\\\\'] }

    rule(:string) do
      str('"') >>
      (escaped_special | special.absent? >> any).repeat.as(:string) >>
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

    rule(:description_example)  do
      ( validity_example | tree_example ) >> newline_or_comment
    end
    rule(:description_examples) do
      (space? >> (comment | description_example)).repeat
    end

    rule(:rule_name) { match['A-Za-z_'] >> match['\w'].repeat >> match['!?'].maybe }
    rule(:rule_description) do
      rule_name.as(:rule_name) >>
      str(':') >> space? >> newline_or_comment >>
      description_examples.as(:examples)
    end
    rule(:rule_descriptions) { rule_description.repeat }

    rule(:spec) do
      str('describe') >> space >>
      (newline.absent? >> any).repeat.as(:spec_name) >> newline_or_comment.repeat >>
      rule_descriptions.as(:rules)
    end

    root :spec
  end
end
