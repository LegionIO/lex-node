require 'simplecov'
SimpleCov.start

require 'bundler/setup'
require 'legion/extensions/node'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
