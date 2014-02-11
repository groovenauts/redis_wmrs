$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'redis_wmrs'

if ENV["COVERAGE"] =~ /yes|on|true/i
  require 'simplecov'
  SimpleCov.start
end
