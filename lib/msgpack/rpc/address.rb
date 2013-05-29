# encoding: utf-8
#
# MessagePack-RPC for Ruby
#
# Copyright (C) 2010-2011 FURUHASHI Sadayuki
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#
require 'socket'

module MessagePack
  module RPC

    # +--+----+
    # | 2|  4 |
    # +--+----+
    # port network byte order
    #    IPv4 address
    #
    # +--+----------------+
    # | 2|       16       |
    # +--+----------------+
    # port network byte order
    #    IPv6 address
    #
    class Address
      include Comparable

      test = ::Socket.pack_sockaddr_in(0, '0.0.0.0')
      if test[0] == "\0"[0] || test[1] == "\0"[0]
        # Linux & Solaris
        SOCKADDR_PACK  = 'S'.freeze
        SOCKADDR_INDEX = 0
      else
        # BSD & OS X
        SOCKADDR_PACK  = 'CC'.freeze
        SOCKADDR_INDEX = 1
      end

      attr_reader :host, :ip, :original, :path, :port

      def initialize(address, port = nil)
        # Allow users to pass in a MessagePack::RPC::Address directly
        if address.is_a?(MessagePack::RPC::Address)
          @host     = address.host
          @ip       = address.ip
          @original = address.original
          @port     = address.port
          @path     = address.path
          return
        end

        if port.nil?
          @original = address
        else
          @original = "#{address}:#{port}"
        end

        host = nil
        path = nil

        if address.is_a?(String) && port.nil?
          if !!(address =~ /\Aunix:/) # UNIX
            path = address.gsub(/\Aunix:/, '')
          elsif !!(address =~ /\A\[.+\]\:\d+\z/) # IPv6
            host, port = address.split(']:')
            host.gsub!(/\A\[/, '')
          else # IPv4 (hopefully)
            host, port = address.split(':')
          end
        end

        if path
          # Ensure path is valid
          @path = ::Socket.unpack_sockaddr_un(::Socket.pack_sockaddr_un(path))
          return
        elsif port.nil?
          raise ArgumentError, "wrong number of arguments (1 for 2)"
        else
          @host = host || address
          @port = port.to_i
        end

        # Is it an IPv4 address?
        if !!(Resolv::IPv4::Regex =~ @host)
          @ip = Resolv::IPv4.create(@host)
        end

        # Guess it's not IPv4! Is it IPv6?
        unless @ip
          if !!(Resolv::IPv6::Regex =~ @host)
            @original = "[#{@host}]:#{@port}"
            @ip = Resolv::IPv6.create(@host)
          end
        end

        # Guess it's not an IP address, so let's try DNS
        unless @ip
          addrs = Array(MessagePack::RPC::Address::DNSResolver.new.resolve(@host))
          raise Resolv::ResolvError, "DNS result has no information for #{@host}" if addrs.empty?
          
          # Pseudorandom round-robin DNS support :/
          @ip = addrs[rand(addrs.size)]
        end

        if !valid_ip?
          raise ArgumentError, "unsupported address class: #{@ip.class}"
        end
      end

      def self.load(binary)
        new(*parse(binary))
      end

      def self.parse(binary)
        sockaddr = parse_sockaddr(binary)
        family   = sockaddr.unpack(SOCKADDR_PACK)[SOCKADDR_INDEX]
        case family
        when ::Socket::AF_UNIX
          "unix:" + ::Socket.unpack_sockaddr_un(sockaddr)
        when ::Socket::AF_INET, ::Socket::AF_INET6
          ::Socket.unpack_sockaddr_in(sockaddr).reverse
        end
      end

      def self.parse_sockaddr(binary)
        binary.force_encoding('ASCII-8BIT') if binary.respond_to?(:encoding)
        data = binary[1..-1]
        case binary[0].unpack('C')[0]
        when ::Socket::AF_UNIX
          addr = ::Socket.pack_sockaddr_un(data)
        else
          if data.bytesize == 6
            addr = ::Socket.pack_sockaddr_in(0, '0.0.0.0')
            addr[2,6] = data[0,6]
          else
            addr = ::Socket.pack_sockaddr_in(0, '::')
            addr[2,2]  = data[0,2]
            addr[8,16] = data[2,16]
          end
        end
        addr
      end

      def ==(o)
        eql?(o)
      end

      def <=>(o)
        dump <=> o.dump
      end

      def dump
        @serialized ||= begin
          if unix?
            [::Socket::AF_UNIX].pack('C') + path
          else
            packed = ::Socket.pack_sockaddr_in(port, ip.to_s)
            if ipv4?
              [::Socket::AF_INET].pack('C') + packed[2,6]
            elsif ipv6?
              [::Socket::AF_INET6].pack('C') + packed[2,2] + packed[8,16]
            else
              raise ArgumentError, "unsupported address class: #{host.class}"
            end
          end
        end
      end

      def eql?(o)
        o.is_a?(Address) && dump.eql?(o.dump)
      end

      def hash
        dump.hash
      end

      def inspect
        "#<#{self.class} \"#{to_s}\">"
      end

      def ipv4?
        ip.is_a?(Resolv::IPv4)
      end

      def ipv6?
        ip.is_a?(Resolv::IPv6)
      end

      def unix?
        path.is_a?(String)
      end

      def sockaddr
        self.class.parse_sockaddr(dump)
      end

      def to_a
        if unix?
          [path]
        else
          [ip.to_s, port]
        end
      end

      def to_msgpack(*args)
        MessagePack.pack(dump, *args)
      end

      def to_s
        if unix?
          "unix:#{path}"
        else
          host_string = ipv6? ? "[#{host}]" : host.to_s
          [host_string, port].join(':')
        end
      end

      def valid?
        unix? or (valid_ip? and valid_port?)
      end
      alias connectable? valid?

      def valid_ip?
        ipv4? or ipv6?
      end

      def valid_port?
        !port.nil? && port != 0
      end

    end
  end
end

require 'msgpack/rpc/address/dns_resolver'
