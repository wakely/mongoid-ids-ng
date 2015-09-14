# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'mongoid/ids/version'

Gem::Specification.new do |s|
  s.name        = 'mongoid-ids'
  s.version     = Mongoid::Ids::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Nicholas Bruning', 'Marcos Piccinini']
  s.homepage    = 'http://github.com/nofxx/mongoid-ids'
  s.licenses    = ['MIT']
  s.summary     = 'A little random, unique id/token generator for Mongoid documents.'
  s.description = 'Mongoid Ids creates random, unique tokens for mongoid documents. Highly configurable and great for making URLs a little more compact.'

  s.rubyforge_project = 'mongoid-ids'
  s.add_dependency 'mongoid', '>= 5.0.0'
  s.add_dependency 'loofah', '> 2.0.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
