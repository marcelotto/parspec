# -*- ruby -*-

format = 'doc' # 'doc' for more verbose, 'progress' for less
tags   = %w[ ] #

guard 'rspec',
      cmd: "bundle exec rspec --format #{format} #{tags.map{|tag| "--tag #{tag}"}.join(' ')}",
      all_after_pass: false do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})             { |m| "spec/#{m[1]}_spec.rb" }
  watch('lib/parspec.rb')               { 'spec' }
  watch('spec/spec_helper.rb')          { 'spec' }
  watch(/spec\/support\/(.+)\.rb/)      { 'spec' }
end
