require 'bundler/setup'
Bundler.require(:test)

require 'parspec'

SPEC_DIR = File.dirname(__FILE__)
Dir[File.join(SPEC_DIR, 'support/**/*.rb')].each {|f| require f }

RSpec.configure do |config|
  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

end
