# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'faraday_json/version'

Gem::Specification.new do |spec|
  spec.name          = "faraday_json"
  spec.version       = FaradayJSON::VERSION
  spec.authors       = ["Jens Finkhaeuser"]
  spec.email         = ["foss@spritecloud.com"]
  spec.description   = %q{This is a character encoding-aware JSON middleware for Faraday.}
  spec.summary       = %q{This is a character encoding-aware JSON middleware for Faraday.}
  spec.homepage      = "https://github.com/spriteCloud/faraday_json"
  spec.license       = "MITNFA"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake"
#  spec.add_development_dependency "simplecov"

#  spec.add_dependency "thor", "~> 0.19"
#  spec.add_dependency "facets", "~> 2.9"
#  spec.add_dependency "json", "~> 1.8.1"
  spec.add_dependency "faraday", "~> 0.9.0"
#  spec.add_dependency "faraday_middleware", "~> 0.9.1"
#  spec.add_dependency "multi_xml", "~> 0.5.5"
#  spec.add_dependency "teelogger", "~> 0.4.0"
#  spec.add_dependency "minitest", "~> 5.5.1"
end
