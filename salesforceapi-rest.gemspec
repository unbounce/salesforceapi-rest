# -*- encoding: utf-8 -*-
require File.expand_path('../lib/salesforceapi-rest/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Lucas Allan Amorim"]
  gem.email         = ["lucas.allan@gmail.com"]
  gem.description   = %q{Ruby wrapper to access salesforce rest api}
  gem.summary       = %q{Ruby wrapper to access salesforce rest api}
  gem.homepage      = ""

  gem.files         = Dir['lib/**/*.rb']
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "salesforceapi-rest"
  gem.require_paths = ["lib"]
  gem.version       = Salesforceapi::Rest::VERSION

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rack-test'
  gem.add_development_dependency "rforce"
  gem.add_development_dependency "omniauth"
  gem.add_development_dependency "httparty"
  gem.add_development_dependency "activeresource"
  gem.add_development_dependency "crack"
  gem.add_development_dependency "builder"
end
