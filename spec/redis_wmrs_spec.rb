require 'spec_helper'

describe RedisWmrs do
  it 'should have a version number' do
    RedisWmrs::VERSION.should_not be_nil
  end

  describe ".new" do
    let(:instance){ RedisWmrs.new(master_name: "sentinel_apisrv") }
    it{ expect(instance).to be_a(::Redis) }
    it{ expect(instance).to be_a(RedisWmrs::Impl) }
    it{ expect(instance).to_not be_a(RedisWmrs) }
  end
end
