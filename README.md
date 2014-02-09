# RedisWmrs

TODO: Write a gem description

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
