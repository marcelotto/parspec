# coding: utf-8
require 'singleton'
require 'optparse'
require 'pathname'

module Parspec
  class Cli
    include Singleton

    def run(options = {})
      @options = options
      parse_command_line!
      init_output_dir
      puts "Translating #@input #{@print_only ? ' ': "to #@output " }..."
      translation = header + Parspec.translate(@input, @options)
      if @print_only
        puts translation
        exit
      end
      File.open(@output, 'w') { |file| file.write(translation) }
      self
    end

    def header
      @header || <<HEADER
# coding: utf-8
require 'spec_helper'
require 'parslet/convenience'
require 'parslet/rig/rspec'

HEADER
    end

    private

    def parse_command_line!
      optparse = OptionParser.new do |opts|
        opts.banner = 'Usage: parspec [options] PARSPEC_FILE'

        opts.on('-h', '--help', 'Display this information') do
          puts opts
          exit
        end

        opts.on('-v', '--version', 'Print version information') do
          puts "Parspec #{VERSION}"
          exit
        end

        opts.on('-s', '--stdout', 'Print the translation to stdout only') do
          @print_only = true
        end

        opts.on('-o', '--out OUTPUT_FILE', 'Path where translated RSpec file should be stored') do |file|
          @output = file
        end

        opts.on('-b', '--beside-input', 'Put the output file into the same directory as the input') do
          @beside_input = true
        end

        opts.on('-e', '--header HEADER', 'A block of code to be put in front of the translation') do |header|
          @header = header
        end

        opts.on('--no-debug-parse', "Don't print the whole Parslet ascii_tree on errors") do
          @options[:no_debug_parse] = true
        end

      end

      optparse.parse!
      if not input = ARGV.shift
        puts 'Error: no input file given'
        puts optparse
        exit(1)
      end
      if not File.exist?(input)
        puts "Error: couldn't find input file #{input}"
        exit(1)
      end
      @input = input
    end

    def init_output_dir
      default_dir = File.dirname(@input)
      default_basename = File.basename(@input, File.extname(@input)) + '.rb'

      # no output defined
      @output = if not @output
        File.join (@beside_input ? default_dir : '.'), default_basename
      # only path given
      elsif Dir.exist?(@output) or @output.end_with?(File::SEPARATOR) or
          (File::ALT_SEPARATOR and @output.end_with?(File::ALT_SEPARATOR))
        warn('Ignoring -b, since directory specified') if @beside_input
        File.join @output, default_basename
      # directory and name given
      elsif File.dirname(@output) != '.'
        warn('Ignoring -b, since directory specified') if @beside_input
        @output
      # only name given
      else
        File.join (@beside_input ? default_dir : '.'), @output
      end
    end

  end

  CLI = Cli.instance
end
