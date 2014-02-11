require 'spec_helper'

describe RedisWmrs::SlaveClient do

  sentinel_slaves = [[
             "name", "192.168.55.105:6379",
             "ip", "192.168.55.105",
             "port", "6379",
             "runid", "ab22538ec61461d0b0dc4723d0e05b12db0142cd",
             "flags", "slave",
             "pending-commands", "0",
             "last-ok-ping-reply", "888",
             "last-ping-reply", "888",
             "info-refresh", "1715",
             "role-reported", "slave",
             "role-reported-time", "82046",
             "master-link-down-time", "0",
             "master-link-status", "ok",
             "master-host", "apisrv01",
             "master-port", "6379",
             "slave-priority", "100",
             "slave-repl-offset", "17680",
            ],
            [
             "name", "192.168.55.104:6379",
             "ip", "192.168.55.104",
             "port", "6379",
             "runid", "c19216b94a2869a64bdbdd823a1d2ccd1783e6c9",
             "flags", "slave",
             "pending-commands", "0",
             "last-ok-ping-reply", "888",
             "last-ping-reply", "888",
             "info-refresh", "1714",
             "role-reported", "slave",
             "role-reported-time", "82046",
             "master-link-down-time", "0",
             "master-link-status", "ok",
             "master-host", "apisrv01",
             "master-port", "6379",
             "slave-priority", "100",
             "slave-repl-offset", "17680",
            ]]

  let(:sentinel){ double(:sentinel) }
  before do
    subject.stub(:sentinel?).and_return(true)
    subject.stub(:establish_connection)
    subject.stub(:auto_retry_with_timeout).and_yield
    subject.stub(:current_sentinel).and_return(sentinel)
    subject.stub(:try_next_sentinel)
    subject.stub(:refresh_sentinels_list)
  end

  describe "#connect" do
    subject{ RedisWmrs::SlaveClient.new(master_name: "sentinel_apisrv") }

    it "fails to connect_with_sentinel" do
      RedisWmrs::SlaveClient.stub(:ip_and_hostnames).and_return(["another", "192.168.55.100"])
      sentinel.should_receive(:sentinel).with("slaves", "sentinel_apisrv").and_return(sentinel_slaves)
      error = "connection error"
      subject.should_receive(:connect_without_sentinel).and_raise(error)
      expect{
        subject.connect
      }.to raise_error(RuntimeError, error)
      failed = subject.instance_variable_get(:@failed)
      expect(failed).to eq ["192.168.55.105:6379"]
    end

    it "removes failed server when connect successfully" do
      RedisWmrs::SlaveClient.stub(:ip_and_hostnames).and_return(["another", "192.168.55.100"])
      sentinel.should_receive(:sentinel).with("slaves", "sentinel_apisrv").and_return(sentinel_slaves)
      subject.instance_variable_set(:@failed, ["192.168.55.105:6379", "192.168.55.104:6379", "apisrv01:6379"])
      subject.should_receive(:connect_without_sentinel)
      subject.connect
      failed = subject.instance_variable_get(:@failed)
      expect(failed).to eq ["192.168.55.104:6379", "apisrv01:6379"]
    end
  end

  describe "#fetch_slaves" do
    subject{ RedisWmrs::SlaveClient.new(master_name: "sentinel_apisrv") }

    it "use master if the process works on same server" do
      RedisWmrs::SlaveClient.stub(:ip_and_hostnames).and_return(["apisrv01", "192.168.55.101"])
      sentinel.should_receive(:sentinel).with("slaves", "sentinel_apisrv").and_return(sentinel_slaves)
      slaves = subject.send(:fetch_slaves)
      m = slaves.first
      expect(m["ip"]).to eq "apisrv01"
      expect(m["port"]).to eq "6379"
      expect(m["slave-priority"]).to eq 0
    end

    it "use slave if the process works on same server" do
      RedisWmrs::SlaveClient.stub(:ip_and_hostnames).and_return(["apisrv02", "192.168.55.104"])
      sentinel.should_receive(:sentinel).with("slaves", "sentinel_apisrv").and_return(sentinel_slaves)
      slaves = subject.send(:fetch_slaves)
      m = slaves.first
      expect(m["ip"]).to eq "192.168.55.104"
      expect(m["port"]).to eq "6379"
      expect(m["slave-priority"]).to eq "100"
    end

    it "pull down priority about the server that failed to connect" do
      RedisWmrs::SlaveClient.stub(:ip_and_hostnames).and_return(["another", "192.168.55.100"])
      sentinel.should_receive(:sentinel).with("slaves", "sentinel_apisrv").and_return(sentinel_slaves)
      subject.instance_variable_set(:@failed, ["192.168.55.105:6379"])
      slaves = subject.send(:fetch_slaves)
      m = slaves.first
      expect(m["ip"]).to eq "192.168.55.104"
      expect(m["port"]).to eq "6379"
      expect(m["slave-priority"]).to eq "100"
    end
  end

end
