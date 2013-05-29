# encoding: utf-8
require 'spec_helper'

describe MessagePack::RPC::Client do
  describe "[instance]" do
    with_client_server
    it_behaves_like "a client"
  end
end
