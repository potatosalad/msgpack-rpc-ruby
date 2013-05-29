# encoding: utf-8
require 'spec_helper'

describe MessagePack::RPC::TCPTransport do
  context "when used for client and server" do
    let(:port)      { MyServer.next_port }
    let(:c_address) { MessagePack::RPC::Address.new('127.0.0.1', port) }
    let(:s_address) { MessagePack::RPC::Address.new('0.0.0.0', port) }
    let(:transport) { MessagePack::RPC::TCPTransport.new }
    let(:listener)  { MessagePack::RPC::TCPServerTransport.new(s_address) }
    let(:server)    { MessagePack::RPC::Server.new }
    let(:client)    { MessagePack::RPC::Client.new(transport, c_address) }

    before(:each) do
      server.listen(listener, MyServer.new(server))
      client.timeout = 10
      @thread = Thread.new do
        server.run
        server.close
      end
    end

    after(:each) do
      stop_server
      stop_client
    end

    describe "client" do
      it_behaves_like "a client"
    end

  end
end
