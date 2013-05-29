# encoding: utf-8
require 'spec_helper'

describe MessagePack::RPC::Loop do
  context "when used for client and server" do
    let(:port)   { MyServer.next_port }
    let(:loop)   { MessagePack::RPC::Loop.new }
    let(:server) { MessagePack::RPC::Server.new(loop) }
    let(:client) { MessagePack::RPC::Client.new('127.0.0.1', port, loop) }

    before(:each) do
      server.listen('0.0.0.0', port, MyServer.new(server))
      client.timeout = 10
    end

    after(:each) do
      client.close
      server.close
    end

    describe "Client#callback" do
      let(:spy) { MySpy.new }

      context "with :hello" do
        it "calls callback with 'ok' result" do
          spy.should_receive(:call).once.and_call_original
          req = client.callback(:hello) do |error, result|
            expect(result).to include('ok')
            expect(error).to  be_nil
            spy.call
          end
          req.get
        end
      end

      context "with :sum, 1, 2" do
        it "calls callback with 3 result" do
          spy.should_receive(:call).once.and_call_original
          req = client.callback(:sum, 1, 2) do |error, result|
            expect(result).to equal 3
            expect(error).to  be_nil
            spy.call
          end
          req.get
        end
      end

      context "with :hello and :sum, 1, 2" do
        it "calls callbacks with 'ok' and 3 results" do
          count = 0

          client.callback(:hello) do |error, result|
            expect(result).to include('ok')
            expect(error).to  be_nil
            count += 1
          end

          client.callback(:sum, 1, 2) do |error, result|
            expect(result).to equal 3
            expect(error).to  be_nil
            count += 1
          end

          while count < 2
            loop.run_once
          end

          expect(count).to equal 2
        end
      end
    end

  end
end
