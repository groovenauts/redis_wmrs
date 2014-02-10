# -*- coding:utf-8 -*-

require 'redis_wmrs'
require 'logger'

@redis = RedisWmrs.new({
  :master_name => "sentinel_apisrv",
  :sentinels => [
    {:host => "redis01", :port => 26379},
    {:host => "redis02", :port => 26379},
    {:host => "redis03", :port => 26379}
  ],
  # :logger => Logger.new(STDOUT)
})

def logging
  master = @redis.client.master.location
  master_sentinel = @redis.client.master.current_sentinel.client.location rescue nil
  slave = @redis.client.slave.location
  slave_sentinel = @redis.client.slave.current_sentinel.client.location rescue nil

  header = "[#{Time.now.to_s}] MASTER:#{master}~#{master_sentinel} SLAVE:#{slave}~#{slave_sentinel}"
  begin
    result = yield
    puts "#{header} #{result}"
  rescue => e
    puts "#{header} [#{e.class.name}]: #{e.message}"
  end
end

i = -1
while true
  i += 1
  i = 0 if i > 10
  logging{ @redis.set("foo", Time.now.to_s) } if i == 0
  logging{ @redis.get('foo') }
  sleep 1
end
