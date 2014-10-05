# coding: utf-8
require 'parslet'
require 'parspec/version'
require 'parspec/parser'
require 'parspec/shared_transform'
require 'parspec/parser_spec_transform'
require 'parspec/transformer_spec_transform'
require 'parspec/cli'

module Parspec

  Error          = Class.new StandardError
  ParseError     = Class.new Error
  TransformError = Class.new Error

  def self.translate(file_or_str, options = {})
    if File.exist?(file_or_str)
      translate_file(file_or_str, options)
    else
      translate_string(file_or_str, options)
    end
  end

  def self.translate_file(filename, options = {})
    translate_string(File.read(filename), options)
  end

  def self.translate_string(str, options = {})
    ParserSpecTransform.no_debug_parse = options[:no_debug_parse]
    tree = Parser.new.parse(str)
    tree = SharedTransform.new.apply(tree)
    translation = Parslet::Transform.new do
      spec = ->(type) {
        { header: {type: type, subject_class: simple(:subject_class) },
          rules: subtree(:rules) } }
      rule(spec['parser'])      { ParserSpecTransform.new.apply(tree) }
      rule(spec['transformer']) { TransformerSpecTransform.new.apply(tree) }
    end.apply(tree)
    raise Error, "unexpected translation: #{translation}" unless translation.is_a? String
    translation
  rescue Parslet::ParseFailed => e
    deepest = deepest_cause e.cause
    line, column = deepest.source.line_and_column(deepest.pos)
    raise ParseError, "unexpected input at line #{line} column #{column}"
  end

  # Internal: helper for finding the deepest cause for a parse error
  def self.deepest_cause(cause)
    if cause.children.any?
      deepest_cause(cause.children.first)
    else
      cause
    end
  end

end

def load_parspec(file, options = {})
  parspec_file = case File.extname(file)
    when '.rb' then file.sub(/rb$/, 'parspec')
    when ''    then "#{file}.parspec"
  end

  if not File.exists?(parspec_file)
    # TODO: try to find the file in the load_path
    raise LoadError, "cannot load such file -- #{parspec_file}"
  end

  require 'parslet/convenience'
  require 'parslet/rig/rspec'

  parspec = Parspec.translate_file(parspec_file, options)
  # TODO: These are not detected as examples by RSpec ...
  #tmp_file = Tempfile.new([File.basename(parspec_file), '.rb'])
  #tmp_file.write(parspec)
  #require tmp_file.path
  # only as a fallback or if options[:force_eval]
  eval(parspec)
end
