# require 'codeclimate-test-reporter'
# CodeClimate::TestReporter.start

$LOAD_PATH << File.expand_path('../../lib', __FILE__)

# require 'pry'
# require 'database_cleaner'
require 'mongoid'
require 'mongoid-rspec'

require 'mongoid/ids'

ENV['MONGOID_ENV'] = 'test'

Mongoid.configure do |config|
  config.load_configuration(
    clients: {
      default: {
        database: 'mongoid_ids_test',
        hosts: ["localhost: #{ENV['BOXEN_MONGODB_PORT'] || 27_017}"],
        options: {}
      }
    })
end

Mongo::Logger.logger.level = Logger::INFO

RSpec.configure do |config|
  config.include Mongoid::Matchers

  config.before(:each) do
    Mongoid.purge!
  end

  config.after(:suite) do
    puts "\n# With Mongoid v#{Mongoid::VERSION}"
  end
end
