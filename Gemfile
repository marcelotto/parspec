source 'https://rubygems.org'

# Specify your gem's dependencies in parspec.gemspec
gemspec

group :test, :development do
  gem 'guard-rspec'
  gem 'wdm', '>= 0.1.0' if RbConfig::CONFIG['target_os'] =~ /mswin|mingw|cygwin/i
end
