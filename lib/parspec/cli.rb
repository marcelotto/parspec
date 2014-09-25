# coding: utf-8
require 'singleton'
require 'optparse'

module Parspec
  class Cli
    include Singleton

    def run(options = {})
      @options = options
      parse_command_line!
      puts "Translating #{@options[:input]} to #{@options[:output]} ..."
      translation = header + Parspec.translate(@options[:input])
      if @options[:print_only]
        puts translation
        exit
      end
      File.open(@options[:output], 'w') { |file| file.write(translation) }
      self
    end

    def header
      return @options[:header] if @options[:header]
      <<HEADER
# coding: utf-8
require 'spec_helper'
require 'parslet/rig/rspec'

HEADER
    end

    private

    def parse_command_line!
      optparse = OptionParser.new do |opts|
        opts.banner = 'Usage: parspec [options] PARSPEC_FILE'

        opts.on( '-h', '--help', 'Display this information' ) do
          puts opts
          exit
        end

        opts.on( '-v', '--version', 'Print version information' ) do
          puts "Parspec #{VERSION}"
          exit
        end

        opts.on( '-p', '--print', 'Print the translation to stdout only' ) do
          @options[:print_only] = true
        end

        opts.on( '-o', '--out OUTPUT_FILE', 'Path where translated RSpec file should be stored' ) do |file|
          @options[:output] = file
        end

        opts.on( '-e', '--header HEADER', 'A block of code to be put in front of the translation' ) do |header|
          @options[:header] = header
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
      @options[:input] = input
      @options[:output] ||= File.join(File.dirname(input), File.basename(input, File.extname(input)) + '.rb')
    end

  end

  CLI = Cli.instance
end
