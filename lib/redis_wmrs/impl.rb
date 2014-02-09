require 'redis_wmrs'

module RedisWmrs
  class Impl < ::Redis

    def initialize(options = {})
      dispatch_options = options.delete(:dispatch) || options.delete("dispatch") || {}
      super(options.dup) # Redis#initialize
      m = @client # master client
      s = SlaveClient.new(options)
      @original_client = @client = RedisWmrs::Dispatcher.new(m, s, dispatch_options)
    end
  end
end
