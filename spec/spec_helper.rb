# require 'codeclimate-test-reporter'
# CodeClimate::TestReporter.start

$: << File.expand_path("../../lib", __FILE__)

# require 'pry'
# require 'database_cleaner'
require 'mongoid'
require 'mongoid-rspec'

require 'mongoid/ids'

ENV['MONGOID_ENV'] = "test"

Mongoid.configure do |config|
  config.sessions = {
    default: {
      database: 'mongoid_ids_test',
      hosts: [ "localhost:#{ENV['BOXEN_MONGODB_PORT'] || 27017}" ],
      options: {}
    }
  }
end

RSpec.configure do |config|
  config.include Mongoid::Matchers
  # config.before(:suite) do
  # #  DatabaseCleaner.strategy = :truncation
  # end

  config.before(:each) do
   # DatabaseCleaner.clean
    Mongoid.purge!
  end
end
