require 'spec_helper'

describe RedisWmrs::Impl do

  describe "#initialize" do
    let(:instance){ RedisWmrs::Impl.new(master_name: "sentinel_apisrv") }
    it{ expect(instance.client).to be_a(RedisWmrs::Dispatcher) }
  end

end
