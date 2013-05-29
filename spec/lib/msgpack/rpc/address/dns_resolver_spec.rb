# encoding: utf-8
require 'spec_helper'

describe MessagePack::RPC::Address::DNSResolver do
  it "resolves domain names" do
    resolver = MessagePack::RPC::Address::DNSResolver.new
    expect(resolver.resolve("msgpack.org")).to eq Resolv::IPv4.create("49.212.29.180")
  end

  it "resolves CNAME responses" do
    resolver = MessagePack::RPC::Address::DNSResolver.new
    results = resolver.resolve("www.google.com")
    if results.is_a?(Array)
      expect(results.all? {|i| i.is_a?(Resolv::IPv4) }).to be_true
    else
      expect(results.is_a?(Resolv::IPv4)).to be_true
    end
    # www.yahoo.com will be resolved randomly whether multiple or
    # single entry.
    results = resolver.resolve("www.yahoo.com")
    if results.is_a?(Array)
      expect(results.all? {|i| i.is_a?(Resolv::IPv4) }).to be_true
    else
      expect(results.is_a?(Resolv::IPv4)).to be_true
    end
  end
end
