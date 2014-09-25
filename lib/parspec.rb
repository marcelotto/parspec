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

  def self.translate(file_or_str)
    if File.exist?(file_or_str)
      translate_file(file_or_str)
    else
      translate_string(file_or_str)
    end
  end

  def self.translate_file(filename)
    translate_string(File.read(filename))
  end

  def self.translate_string(str)
    Transform.new.apply(Parser.new.parse(str))
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
