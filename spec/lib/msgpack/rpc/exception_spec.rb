# encoding: utf-8
require 'spec_helper'

describe MessagePack::RPC::TimeoutError do
  context "when client timeout exceeded" do
    let(:port)   { MyServer.next_port }
    let(:client) { MessagePack::RPC::Client.new('127.0.0.1', port) }
    let(:socket) { TCPServer.new('0.0.0.0', client.port) }

    before(:each) do
      client.timeout = 1
      socket
    end

    after(:each) do
      client.close
      socket.close
    end

    it "raises MessagePack::RPC::TimoutError" do
      expect { client.call(:hello) }.to raise_error(MessagePack::RPC::TimeoutError)
    end
  end
end