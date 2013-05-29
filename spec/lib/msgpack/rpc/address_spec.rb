# encoding: utf-8
require 'spec_helper'

describe MessagePack::RPC::Address do
  it "can be packed and unpacked using MessagePack" do
    address = MessagePack::RPC::Address.new('172.16.0.11', 18900)
    packed  = address.to_msgpack
    message = MessagePack.unpack(packed)
    expect(MessagePack::RPC::Address.load(message)).to eq address
  end

  describe "#initialize" do

    let(:arguments) { [] }
    subject { described_class.new(*arguments) }

    context "with '127.0.0.1:18800'" do
      let(:arguments) { ['127.0.0.1:18800'] }

      its(:original) { should eq('127.0.0.1:18800') }
      its(:host)     { should eq('127.0.0.1') }
      its(:ip)       { should eq(Resolv::IPv4.create('127.0.0.1')) }
      its(:path)     { should be_nil }
      its(:port)     { should eq(18800) }

      it { should be_ipv4 }
      it { should be_valid }

      describe "to_msgpack" do
        context "when unpacked" do
          bytearray = [167, ::Socket::AF_INET, 73, 112, 127, 0, 0, 1]
          it "should eq #{bytearray.inspect}" do
            expect(subject.to_msgpack.unpack('C*')).to eq(bytearray)
          end
        end
      end
    end

    context "with '127.0.0.1', 18800" do
      let(:arguments) { ['127.0.0.1', 18800] }

      its(:original) { should eq('127.0.0.1:18800') }
      its(:host)     { should eq('127.0.0.1') }
      its(:ip)       { should eq(Resolv::IPv4.create('127.0.0.1')) }
      its(:path)     { should be_nil }
      its(:port)     { should eq(18800) }

      it { should be_ipv4 }
      it { should be_valid }

      describe "to_msgpack" do
        context "when unpacked" do
          bytearray = [167, ::Socket::AF_INET, 73, 112, 127, 0, 0, 1]
          it "should eq #{bytearray.inspect}" do
            expect(subject.to_msgpack.unpack('C*')).to eq(bytearray)
          end
        end
      end
    end

    context "with 'localhost:18800'" do
      let(:arguments) { ['localhost:18800'] }

      its(:original) { should eq('localhost:18800') }
      its(:host)     { should eq('localhost') }
      its(:ip)       { should eq(Resolv::IPv4.create('127.0.0.1')) }
      its(:path)     { should be_nil }
      its(:port)     { should eq(18800) }

      it { should be_ipv4 }
      it { should be_valid }

      describe "to_msgpack" do
        context "when unpacked" do
          bytearray = [167, ::Socket::AF_INET, 73, 112, 127, 0, 0, 1]
          it "should eq #{bytearray.inspect}" do
            expect(subject.to_msgpack.unpack('C*')).to eq(bytearray)
          end
        end
      end
    end

    context "with 'localhost', 18800" do
      let(:arguments) { ['localhost', 18800] }

      its(:original) { should eq('localhost:18800') }
      its(:host)     { should eq('localhost') }
      its(:ip)       { should eq(Resolv::IPv4.create('127.0.0.1')) }
      its(:path)     { should be_nil }
      its(:port)     { should eq(18800) }

      it { should be_ipv4 }
      it { should be_valid }

      describe "to_msgpack" do
        context "when unpacked" do
          bytearray = [167, ::Socket::AF_INET, 73, 112, 127, 0, 0, 1]
          it "should eq #{bytearray.inspect}" do
            expect(subject.to_msgpack.unpack('C*')).to eq(bytearray)
          end
        end
      end
    end

    context "with 'notahost:18800'" do
      let(:arguments) { ['notahost:18800'] }

      it "raises Resolv::ResolvError" do
        expect { subject }.to raise_error(Resolv::ResolvError)
      end
    end

    context "with '[::7f00:1]:18800'" do
      let(:arguments) { ['[::7f00:1]:18800'] }

      its(:original) { should eq('[::7f00:1]:18800') }
      its(:host)     { should eq('::7f00:1') }
      its(:ip)       { should eq(Resolv::IPv6.create('::7f00:1')) }
      its(:path)     { should be_nil }
      its(:port)     { should eq(18800) }

      it { should be_ipv6 }
      it { should be_valid }

      describe "to_msgpack" do
        context "when unpacked" do
          bytearray = [179, ::Socket::AF_INET6, 73, 112, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 127, 0, 0, 1]
          it "should eq #{bytearray.inspect}" do
            expect(subject.to_msgpack.unpack('C*')).to eq(bytearray)
          end
        end
      end
    end

    context "with '::7f00:1', 18800" do
      let(:arguments) { ['::7f00:1', 18800] }

      its(:original) { should eq('[::7f00:1]:18800') }
      its(:host)     { should eq('::7f00:1') }
      its(:ip)       { should eq(Resolv::IPv6.create('::7f00:1')) }
      its(:path)     { should be_nil }
      its(:port)     { should eq(18800) }

      it { should be_ipv6 }
      it { should be_valid }

      describe "to_msgpack" do
        context "when unpacked" do
          bytearray = [179, ::Socket::AF_INET6, 73, 112, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 127, 0, 0, 1]
          it "should eq #{bytearray.inspect}" do
            expect(subject.to_msgpack.unpack('C*')).to eq(bytearray)
          end
        end
      end
    end

    context "with 'unix:/tmp/test.sock'" do
      let(:arguments) { ['unix:/tmp/test.sock'] }

      its(:original) { should eq('unix:/tmp/test.sock') }
      its(:host)     { should be_nil }
      its(:ip)       { should be_nil }
      its(:path)     { should eq('/tmp/test.sock') }
      its(:port)     { should be_nil }

      it { should be_unix }
      it { should be_valid }

      describe "to_msgpack" do
        context "when unpacked" do
          bytearray = [175, ::Socket::AF_UNIX, 47, 116, 109, 112, 47, 116, 101, 115, 116, 46, 115, 111, 99, 107]
          it "should eq #{bytearray.inspect}" do
            expect(subject.to_msgpack.unpack('C*')).to eq(bytearray)
          end
        end
      end
    end

    context "with MessagePack::RPC::Address" do
      let(:arguments) { [described_class.new('127.0.0.1:18800')] }

      its(:original) { should eq('127.0.0.1:18800') }
      its(:host)     { should eq('127.0.0.1') }
      its(:ip)       { should eq(Resolv::IPv4.create('127.0.0.1')) }
      its(:path)     { should be_nil }
      its(:port)     { should eq(18800) }

      it { should be_ipv4 }
      it { should be_valid }

      describe "to_msgpack" do
        context "when unpacked" do
          bytearray = [167, ::Socket::AF_INET, 73, 112, 127, 0, 0, 1]
          it "should eq #{bytearray.inspect}" do
            expect(subject.to_msgpack.unpack('C*')).to eq(bytearray)
          end
        end
      end
    end

  end
end
