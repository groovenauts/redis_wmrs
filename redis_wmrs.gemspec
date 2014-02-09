# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis_wmrs/version'

Gem::Specification.new do |spec|
  spec.name          = "redis_wmrs"
  spec.version       = RedisWmrs::VERSION
  spec.authors       = ["akima"]
  spec.email         = ["akima@groovenauts.jp"]
  spec.description   = %q{redis client to write to master node and read from slave node}
  spec.summary       = %q{redis client to write to master node and read from slave node}
  spec.homepage      = "https://github.com/groovenauts/redis_wmrs"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "redis"         , "~> 3.0.0"
  spec.add_runtime_dependency "redis-sentinel", "~> 1.4.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
end
