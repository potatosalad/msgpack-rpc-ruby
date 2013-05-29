shared_examples_for "a client" do

  describe "#call" do
    context "with :hello" do
      it "returns 'ok' value" do
        expect(client.call(:hello)).to include('ok')
      end
    end

    context "with :sum, 1, 2" do
      it "returns 3 value" do
        expect(client.call(:sum, 1, 2)).to eq(3)
      end
    end

    context "with :hidden" do
      it "raises MessagePack::RPC::RemoteError" do
        expect { client.call(:hidden) }.to raise_error(MessagePack::RPC::RemoteError)
      end
    end

    context "with :exception" do
      it "raises MessagePack::RPC::RemoteError" do
        expect { client.call(:exception) }.to raise_error(MessagePack::RPC::RemoteError, 'raised')
      end
    end

    context "with :async" do
      it "returns 'async' value" do
        expect(client.call(:async)).to include('async')
      end
    end

    context "with :async_exception" do
      it "raises MessagePack::RPC::RemoteError" do
        expect { client.call(:async_exception) }.to raise_error(MessagePack::RPC::RemoteError, 'async')
      end
    end
  end

  describe "#call_async" do
    context "with :hello and with :sum, 1, 2" do
      it "returns 'ok' and 3 values" do
        req1 = client.call_async(:hello)
        req2 = client.call_async(:sum, 1, 2)

        req1.join
        expect(req1.result).to include('ok')
        expect(req1.error).to  be_nil

        req2.join
        expect(req2.result).to equal 3
        expect(req2.error).to  be_nil
      end
    end
  end

  describe "#callback" do
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
  end

  describe "#notify" do
    context "with :hello" do
      it "returns nil" do
        expect(client.notify(:hello)).to be_nil
      end
    end

    context "with :sum, 1, 2" do
      it "returns nil" do
        expect(client.notify(:sum, 1, 2)).to be_nil
      end
    end
  end

end