# coding: utf-8
require 'parslet'
require 'parspec/version'
require 'parspec/parser'
require 'parspec/transform'
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
    Transform.no_debug_parse = options[:no_debug_parse]
    translation = Transform.new.apply(Parser.new.parse(str))
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
