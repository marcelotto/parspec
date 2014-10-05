module Parspec
  class Parser < Parslet::Parser
    rule(:eof)      { any.absent? }
    rule(:space)    { match[' \t'].repeat(1) }
    rule(:newline)  { match['\n'] }
    rule(:newlines) { newline.repeat(1) | eof }
    rule(:comment)  { str('#') >> match_till(:newlines).maybe >> (newline | eof) }
    rule(:ws)       { (space | newline | comment).repeat(1) }
    rule(:ws?)      { ws.maybe }

    rule(:special)         { match['"\\\\'] }
    rule(:escaped_special) { str("\\") >> match['tnr"\\\\'] }
    rule(:string) do
      str('"') >>
        ((escaped_special | special.absent? >> any).repeat).as(:string) >>
      str('"') >> ws?
    end

    rule(:rule_name) do
      match['A-Za-z_'] >> match['\w'].repeat >> match['!?'].maybe
    end

    rule(:validity) { (stri('OK') | stri('FAIL')).as(:status) >> ws? }
    rule(:validity_example) { string.as(:input) >> validity.as(:validity) }

    rule(:mapping_example) do
      string.as(:input) >> ws? >> str('->') >> ws? >> string.as(:output)
    end

    rule(:include_example) do
      str('include') >> space >> rule_name.as(:include_rule)
    end

    rule(:description_example) do
      (validity_example | mapping_example | include_example) >> ws?
    end
    rule(:description_examples) { description_example.repeat }

    rule(:rule_description) do
      rule_name.as(:rule_name) >> str(':') >> ws? >>
      description_examples.as(:examples)
    end
    rule(:rule_descriptions) { rule_description.repeat }

    rule(:spec_header) do
      (str('parser') | str('transformer')).as(:type) >> space >>
      match_till { newline | comment }.as(:subject_class) >> ws?
    end

    rule(:spec) do
      ws? >> (spec_header.as(:header) >> rule_descriptions.as(:rules) | eof)
    end

    root :spec

  private

    def match_till(ending = nil)
      case ending
        when String then (str(ending).absent? >> any).repeat(1)
        when Symbol then (send(ending).absent? >> any).repeat(1)
        when nil
          raise ParserError, 'expected a block' unless block_given?
          (yield.absent? >> any).repeat(1)
      end
    end

    def stri(str)
      key_chars = str.split(//)
      key_chars
        .collect! { |char| match["#{char.upcase}#{char.downcase}"] }
        .reduce(:>>)
    end

  end
end
