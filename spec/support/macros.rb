# encoding: utf-8
module Support
  module Macros
    module ClassMethods

      def with_client_server(&block)
        let(:port)   { MyServer.next_port }
        let(:client) { MessagePack::RPC::Client.new('127.0.0.1', port) }
        let(:server) { MessagePack::RPC::Server.new }

        if block_given?
          before(:each, &block)
        else
          before(:each) do
            start_server
            start_client
          end
        end

        after(:each) do
          stop_server
          stop_client
        end
      end

    end

    def start_client
      client.timeout = 10
    end

    def start_server
      server.listen('0.0.0.0', port, MyServer.new(server))
      @thread = Thread.new do
        server.run
        server.close
      end
    end

    def stop_client
      client.close
    end

    def stop_server
      server.stop rescue nil
      begin
        Timeout.timeout(1) { @thread.join }
      rescue Timeout::Error
        @thread.kill
        sleep 0.1
      end
    end

  end
end

RSpec.configure do |config|
  config.extend  Support::Macros::ClassMethods
  config.include Support::Macros
end
