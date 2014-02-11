require 'spec_helper'

describe RedisWmrs::Dispatcher do

  describe "#initialize" do
    let(:master_client){ Redis::Client.new(options) }
    let(:slave_client){ RedisWmrs::SlaveClient.new(options) }
    let(:options){ {master_name: "sentinel_apisrv"} }
    let(:instance){ RedisWmrs::Dispatcher.new(master_client, slave_client, options) }
    it{ expect(instance.master).to eq master_client }
    it{ expect(instance.slave).to eq slave_client }
  end

  call_actions = [:call, :call_loop, :call_with_timeout, :call_without_timeout].freeze

  def args_for_call(action, args, timeout = 1)
    return (action == :call_with_timeout) ? [args, timeout] : [args]
  end

  context "original methods" do
    let(:master_client){ double(:master) }
    let(:slave_client){ double(:slave) }
    let(:options){ {master_name: "sentinel_apisrv"} }
    subject{ RedisWmrs::Dispatcher.new(master_client, slave_client, options) }

    it "#ids" do
      master_client.stub(:id).and_return("redis://192.168.55.101:6379/1")
      slave_client.stub(:id).and_return("redis://192.168.55.104:6379/1")
      expect(subject.ids).to eq ["redis://192.168.55.101:6379/1", "redis://192.168.55.104:6379/1"]
    end

    it "#locations" do
      master_client.stub(:location).and_return("192.168.55.101:6379")
      slave_client.stub(:location).and_return("192.168.55.104:6379")
      expect(subject.locations).to eq ["192.168.55.101:6379", "192.168.55.104:6379"]
    end
  end

  context "default behavior" do
    let(:master_client){ double(:master) }
    let(:slave_client){ double(:slave) }
    let(:options){ {master_name: "sentinel_apisrv"} }
    subject{ RedisWmrs::Dispatcher.new(master_client, slave_client, options) }

    context "both client work to" do
      [:connect, :disconnect, :reconnect].each do |m|
        describe m do
          before do
            master_client.should_receive(m)
            slave_client.should_receive(m)
          end
          it{ subject.send(m) }
        end
      end

      [:db=, :logger=].each do |m|
        describe m do
          let(:arg){ Object.new }
          before do
            master_client.should_receive(m).with(arg)
            slave_client.should_receive(m).with(arg)
          end
          it{ subject.send(m, arg) }
        end
      end

      call_actions.each do |action|
        describe action do
          [
           [:select, 5],
           [:quit],
          ].each do |args|
            it args.first do
              args = args_for_call(action, args)
              master_client.should_receive(action).with(*args)
              slave_client.should_receive(action).with(*args)
              subject.send(action, *args)
            end
          end
        end
      end
    end

    context "slave client work to" do
      call_actions.each do |action|
        describe action do
          [
           [:keys],
           [:keys, "foo*"],
           [:randomkey],
           [:get, "foo"],
           [:mget, "foo", "bar"],
          ].each do |args|
            it args.first do
              args = args_for_call(action, args)
              slave_client.should_receive(action).with(*args)
              subject.send(action, *args)
            end
          end
        end
      end
    end

    context "master client work to" do
      call_actions.each do |action|
        describe action do
          [
           [:del, "foo"],
           [:set, "foo", "bar"],
           [:setex, "foo", 100, "bar"],
           [:mset, "foo", 1, "bar", 100],
          ].each do |args|
            it args.first do
              args = args_for_call(action, args)
              master_client.should_receive(action).with(*args)
              subject.send(action, *args)
            end
          end
        end
      end
    end

  end


end
