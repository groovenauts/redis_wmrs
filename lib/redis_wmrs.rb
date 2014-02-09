require "redis_wmrs/version"

require "redis"
require 'redis-sentinel'

module RedisWmrs

  autoload :Impl       , 'redis_wmrs/impl'
  autoload :Dispatcher , 'redis_wmrs/dispatcher'
  autoload :SlaveClient, 'redis_wmrs/slave_client'

  def self.new(options = {})
    RedisWmrs::Impl.new(options)
  end

end
