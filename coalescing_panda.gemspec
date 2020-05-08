$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "coalescing_panda/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "coalescing_panda"
  s.version     = CoalescingPanda::VERSION
  s.authors     = ["Nathan Mills"]
  s.email       = ["nathanm@instructure.com"]
  s.homepage    = "http://www.instructure.com"
  s.summary     = "Canvas LTI and OAUTH2 mountable engine"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 4.0.1"
  s.add_dependency "bearcat", "~> 0.9.20"
  s.add_dependency "macaddr", "1.6.1"
  s.add_dependency "ims-lti", "~> 2.0"
  s.add_dependency "haml-rails"
  s.add_dependency "sass-rails", "~> 4.0.0"
  s.add_dependency "jquery-rails"
  s.add_dependency "coffee-rails", "~> 4.0.0"
  s.add_dependency 'protected_attributes'
  s.add_dependency 'p3p'
  s.add_dependency 'useragent'
  s.add_dependency 'browser', "< 2.0.0"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "shoulda-matchers"
  s.add_development_dependency "nokogiri"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "debugger"
  s.add_development_dependency "pry"
end
