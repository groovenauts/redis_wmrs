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
          it :select do
            args = (action == :call_with_timeout) ? [[:select, 5], 1] : [[:select, 5]] # 5 means another DB on redis
            master_client.should_receive(action).with(*args)
            slave_client.should_receive(action).with(*args)
            subject.send(action, *args)
          end

          it :quit do
            args = (action == :call_with_timeout) ? [[:quit], 1] : [[:quit]]
            master_client.should_receive(action).with(*args)
            slave_client.should_receive(action).with(*args)
            subject.send(action, *args)
          end
        end
      end
      
    end

  end


end
