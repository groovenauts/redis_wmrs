# redis_wmrs

There are some client libraries for [redis](http://redis.io/) on ruby.

https://rubygems.org/search?query=redis

[redis-sentinel](https://github.com/flyerhzm/redis-sentinel) works well
with redis and redis sentinel cluster. But it look up master node only.
Even if there are a lot of redis-servers, each redis client connect to
only one redis-server.


## Write master, Read slave

If you want to distribute the accesses from redis clients to master node,
your application should read data from slave node and write to master node.

RedisWmrs makes 2 redis-sentinel clients look 1 client.



## Background

![](https://cacoo.com/diagrams/5Rfve7mdSxEvMjwq-3F688.png)


## Performance

We made a benchmark tool [redis_cluster_cache_benchmark](https://github.com/groovenauts/redis_cluster_cache_benchmark) for cache with a master-slave cluster.

This tool can run scenario by using one of these three mechanisms.

| Name         | Cache place | Write     | Read        |
| ------------ |-------------|-----------|-------------|
| Memory cache | Memory      | memory    | memory      |
| Redis        | Redis       | to master | from master |
| RedisWmrs    | Redis       | to master | from slave  |

### A result on VMs

* 10 VMs on iMac, 10 worker process run on each VM.
* the scenario is just GET or SET.
* 1 test repeats the scenario 10,000 times.
* Master redis node is on apisrv01.

| Name         | server   | time(sec) | GET avg(ms) | SET avg(ms) | worker total(KB) | redis-sever(KB) | total(KB) |
| ------------ |:--------:| ---------:| -----------:| -----------:|-----------------:| ---------------:|----------:|
| Memory cache | apisrv01 | 289       |  0.263      |  0.592      | 461,644          |  -              | 461,644   |
| Redis        | apisrv01 | 272       | 25.788      | 28.153      | 118,724          | 75,852          | 194,576   |
| Redis        | apisrv05 | 315       | 29.977      | 34.669      | 120,612          | 73,232          | 193,844   |
| RedisWmrs    | apisrv01 | 201       | 11.681      | 24.778      | 128,884          | 75,420          | 204,304   |
| RedisWmrs    | apisrv05 | 177       |  7.088      | 45.593      | 121,364          | 73,232          | 194,596   |

RedisWmrs works fater than Redis and Memory cache.

For more detail https://github.com/groovenauts/redis_cluster_cache_benchmark/tree/master/doc/vagrant1

## Installation

Add this line to your application's Gemfile:

    gem 'redis_wmrs'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis_wmrs

## Usage

Almost same as redis or redis-sentinel, but class name is not just Redis but RedisWmrs.

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
