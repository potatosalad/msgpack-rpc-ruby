# encoding: utf-8
require 'spec_helper'

describe MessagePack::RPC::UNIXTransport do
  context "when used for client and server" do
    let(:sock)      { MyServer.next_sock }
    let(:address)   { MessagePack::RPC::Address.new("unix:#{sock}") }
    let(:transport) { MessagePack::RPC::UNIXTransport.new }
    let(:listener)  { MessagePack::RPC::UNIXServerTransport.new(address) }
    let(:server)    { MessagePack::RPC::Server.new }
    let(:client)    { MessagePack::RPC::Client.new(transport, address) }

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
      FileUtils.rm(sock) if File.exist?(sock)
    end

    describe "client" do
      it_behaves_like "a client"
    end

  end
end
