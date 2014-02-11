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

end
