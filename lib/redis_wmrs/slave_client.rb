# -*- coding: utf-8 -*-
require 'redis_wmrs'

module RedisWmrs
  class SlaveClient < ::Redis::Client

    # override Redis::Client#connect overwritten by redis-sentinel
    # https://github.com/flyerhzm/redis-sentinel/blob/master/lib/redis-sentinel/client.rb#L24
    def connect
      if sentinel?
        auto_retry_with_timeout do
          discover_slave
          begin
            connect_without_sentinel
          rescue => e
            @failed ||= []
            f = "#{@options[:host]}:#{@options[:port]}"
            @failed.delete(f)
            @failed.push(f) # 必ず末尾に追加する
            raise e
          else
            @failed.delete("#{@options[:host]}:#{@options[:port]}") if @failed
          end
        end
      else
        connect_without_sentinel
      end
    end

    def discover_slave
      while true
        try_next_sentinel
        host_attrs = fetch_slaves
        host_attrs.each do |attrs|
          begin
            host, port = attrs["ip"], attrs["port"]
            if host && port
              # An ip:port pair
              @options.merge!(:host => host, :port => port.to_i, :password => @master_password)
              refresh_sentinels_list
              return
            else
              # A null reply
            end
          rescue Redis::CommandError => e
            raise unless e.message.include?("IDONTKNOW")
          rescue Redis::CannotConnectError
            # faile to connect to current sentinel server
          end
        end
      end
    end

    MASTER_PRIORITY = 0

    def fetch_slaves
      preferred_indexes = []
      slave_attrs_array = current_sentinel.sentinel("slaves", @master_name).map{|pairs| Hash[*pairs]}
      # masterと同じサーバで動作しているクライアントの場合、slaveではなく
      # masterに繋ぐべきなのでマスタも接続先に追加します。
      master_attrs_array = slave_attrs_array.map{|h|
        {"ip" => h["master-host"], "port" => h["master-port"], "slave-priority" => MASTER_PRIORITY}
      }.uniq
      attrs_array = slave_attrs_array + master_attrs_array
      [*self.class.ip_and_hostnames, "127.0.0.1", "localhost"].compact.each do |ip_hostname|
        if idx = attrs_array.index{|attrs| attrs["ip"] ==  ip_hostname}
          preferred_indexes << idx
        end
      end
      # slave-priorityの値が小さいほどmasterに昇格しやすいので、
      # preferredではないslaves群についてはslave-priorityの降順で接続の優先順位を振ります。
      not_preferred = ((0...attrs_array.length).to_a - preferred_indexes).
        sort_by{|i| attrs_array[i]["slave-priority"].to_i}.reverse
      result = (preferred_indexes + not_preferred).map{|i| attrs_array[i]}
      # 接続に失敗した接続先は優先度を下げます
      (@failed || []).each do |failed|
        if idx = result.index{|r| failed == "#{r['ip']}:#{r['port']}" }
          result.push(result.delete_at(idx))
        end
      end
      return result
    end
    private :fetch_slaves

    def self.ip_and_hostnames
      unless @my_hostname
        @my_hostname = Socket::gethostname rescue nil
        @my_ip = IPSocket::getaddress(@my_hostname) rescue nil
      end
      return @my_hostname, @my_ip
    end

  end
end
