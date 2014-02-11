# -*- coding: utf-8 -*-
require 'redis_wmrs'

require 'forwardable'

class RedisWmrs::Dispatcher
  extend Forwardable

  MASTER_SLAVE_COMMANDS = [
    :select, :quit,
  ].freeze

  DEFAULT_SLAVE_COMMANDS = [
    :info, # :sync,
    :dbsize, :lastsave, :time, :ttl, :pttl, :exists, :keys, :randomkey, :type,
    :get, :mget, :getrange, :getbit, :bitcount, :getset, :strlen, :llen,
    :lindex, :srandmember, :sismember, :smembers, :sdiff, :sinter, :sunion,
    :zcard, :zscore, :zrange, :zrevrange, :zrank, :zrevrank, :zrangebyscore,
    :zrevrangebyscore, :zremrangebyscore, :zcount,
    :hlen, :hget, :hmget, :hexists, :hkeys, :hvals, :hgetall,
    # :watch, :unwatch,
    :echo, :ping
  ].freeze

  attr_reader :master, :slave
  attr_reader :options

  def initialize(master, slave, options)
    @master, @slave = master, slave
    @both_cmds = options[:both] || MASTER_SLAVE_COMMANDS
    @slave_cmds = options[:slave] || DEFAULT_SLAVE_COMMANDS
  end

  def ids
    __map__ &:id
  end

  def locations
    __map__ &:location
  end

  def db=(db)
    __both__{|c| c.db = db}; return db
  end

  def logger=(v)
    __both__{|c| c.logger = v}; return v
  end

  def connect   ; __both__{|c| c.connect   }; return self; end
  def disconnect; __both__{|c| c.disconnect}; return self; end
  def reconnect ; __both__{|c| c.reconnect }; return self; end

  def call(command, &block)
    __dispatch__(*command){|c|c.call(command, &block)}
  end

  def call_loop(command, &block)
    __dispatch__(*command){|c|c.call_loop(command, &block)}
  end

  def call_with_timeout(command, timeout, &blk)
    __dispatch__(*command){|c|c.call_with_timeout(command, timeout, &blk)}
  end

  def call_without_timeout(command, &blk)
    __dispatch__(*command){|c|c.call_without_timeout(command, &blk)}
  end

  # すべてのpublicメソッドの定義後で実行する必要があります
  master_deleted_methods = (Redis::Client.public_instance_methods(false).
    delete_if{|s| s =~ /\A_|\Ainitialize|\=$/}) - self.public_instance_methods(false)

  def_delegators :@master, *master_deleted_methods

  private

  def __both__
    yield(@master)
    yield(@slave)
  end
  def __master__; yield(@master); end
  def __slave__ ; yield(@slave ); end

  def __map__
    [yield(@master), yield(@slave)]
  end

  def __dispatch__(command, *, &blk)
    m =
      case
      when @slave_cmds.include?(command) then :__slave__
      when @both_cmds.include?(command)  then :__both__
      else :__master__
      end
    send(m, &blk)
  end

end
