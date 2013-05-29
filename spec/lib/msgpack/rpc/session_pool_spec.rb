# encoding: utf-8
require 'spec_helper'

describe MessagePack::RPC::SessionPool do
  describe "[instance]" do
    with_client_server
    let(:session_pool) { MessagePack::RPC::SessionPool.new }
    let(:session)      { session_pool.get_session('127.0.0.1', client.port) }

    after(:each) do
      session_pool.close
    end

    describe "#call" do
      context "with :hello" do
        it "returns 'ok' value" do
          expect(session.call(:hello)).to include('ok')
        end
      end

      context "with :sum, 1, 2" do
        it "returns 3 value" do
          expect(session.call(:sum, 1, 2)).to eq(3)
        end
      end
    end

  end
end
