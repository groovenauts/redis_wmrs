# redis_wmrs

There are some client libraries for [redis](http://redis.io/) on ruby.

https://rubygems.org/search?query=redis

[redis-sentinel](https://github.com/flyerhzm/redis-sentinel) works well
with redis and redis sentinel cluster. But it look up master node only.
Even if there are a lot of redis-servers, each redis client will connect
to one redis-server.


## Write master, Read slave

If you want to distribute accesses to the master node, you need to read
data from slave node and write to master node.


## Background

![](https://cacoo.com/diagrams/5Rfve7mdSxEvMjwq-3F688.png)



## Installation

Add this line to your application's Gemfile:

    gem 'redis_wmrs'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis_wmrs

## Usage

```

redis = RedisWmrs.new(
  :master_name => "sentinel_master",
  :sentinels => [
    {:host => "redis01", :port => 26379},
    {:host => "redis02", :port => 26379},
    {:host => "redis03", :port => 26379}
  ])

i = -1
while true
  i += 1
  i = 0 if i > 10
  redis.set("foo", Time.now.to_s) if i == 0

  header = "[#{Time.now.to_s}] sentinel:#{redis.client.current_sentinel.client.location} redis:#{redis.client.location}"
  begin
    puts "#{header} #{redis.get 'foo'}"
  rescue => e
    puts "#{header} [#{e.class.name}]: #{e.message}"
  end
  sleep 1
end

```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
