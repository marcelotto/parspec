# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'parspec/version'

Gem::Specification.new do |spec|
  spec.name          = 'parspec'
  spec.version       = Parspec::VERSION
  spec.authors       = ['Marcel Otto']
  spec.email         = ['marcelotto.de@gmail.com']
  spec.summary       = %q{Testing of Parslet grammars and transformations}
  spec.description   = %q{A testing framework for Parslet grammars, in the spirit of gUnit.}
  spec.homepage      = 'http://github.com/marcelotto/parspec'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'parslet'
  spec.add_dependency 'rspec', '~> 3.0'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
end
