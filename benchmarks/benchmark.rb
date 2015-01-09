$: << File.expand_path("../../lib", __FILE__)

require 'database_cleaner'
require 'mongoid'
require 'mongoid/ids'
require 'benchmark'

Mongoid.configure do |config|
  config.connect_to("mongoid_ids_benchmark2")
end

DatabaseCleaner.strategy = :truncation

# start benchmarks

TOKEN_LENGTH = 5

class Link
  include Mongoid::Document
  include Mongoid::Ids
  field :url
  token :length => TOKEN_LENGTH, :contains => :alphanumeric
end

class NoIdsLink
  include Mongoid::Document
  field :url
end

def create_link(token = true)
  if token
    Link.create(:url => "http://involved.com.au")
  else
    NoIdsLink.create(:url => "http://involved.com.au")
  end
end

Link.delete_all
Link.create_indexes
NoIdsLink.delete_all
num_records = [1, 50, 100, 1000, 2000, 3000, 5000, 10000, 30000, 50000]
puts "-- Alphanumeric token of length #{TOKEN_LENGTH} (#{62**TOKEN_LENGTH} possible tokens)"
Benchmark.bm do |b|
  num_records.each do |qty|
    b.report("#{qty.to_s.rjust(5, " ")} records    "){ qty.times{ create_link(false) } }
    b.report("#{qty.to_s.rjust(5, " ")} records tok"){ qty.times{ create_link } }
  end
end
