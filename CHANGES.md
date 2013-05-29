0.6.0
-----
2013-05-29

* Update [Cool.io](https://github.com/tarcieri/cool.io/tree/v1.2.0) to 1.2.0 (removes support for Ruby 1.8)
* Update [msgpack-ruby](https://github.com/msgpack/msgpack-ruby/tree/v0.5.5) to 0.5.5
* Add `MessagePack::RPC::Address::DNSResolver` and rewrite `MessagePack::RPC::Address` to accept IPv4, IPv6, and UNIX addresses.

  Example:

  ```ruby
  # IPv4
  a = MessagePack::RPC::Address.new('localhost:18800')
  b = MessagePack::RPC::Address.new('127.0.0.1', 18800)
  a == b  # => true
  a.ip    # => #<Resolv::IPv4 127.0.0.1>
  a.port  # => 18800
  a.ipv4? # => true

  # IPv6
  a = MessagePack::RPC::Address.new('[::7f00:1]:18800')
  b = MessagePack::RPC::Address.new('::7f00:1', 18800)
  a == b  # => true
  a.ip    # => #<Resolv::IPv6 ::7F00:1>
  a.port  # => 18800
  a.ipv6? # => true

  # UNIX
  a = MessagePack::RPC::Address.new('unix:/tmp/test.sock')
  a.path  # => "/tmp/test.sock"
  a.unix? # => true
  ```

  Credit to [celluloid-io](https://github.com/celluloid/celluloid-io) for the DNSResolver and parts of the Address class.
* Clean up and add specs for UDP and UNIX transports (code coverage is around 80%)
* Ensure UDPSocket gets closed for clients

0.5.1
-----
2012-01-05

* Use ~> version dependency in gemspec

0.5.0
-----
2012-01-05

* Replaced Rev with Cool.io
* MSGPACK-8 RPC::Address.parse_sockaddr(raw) checks encoding of the string on Ruby 1.9

0.4.4
-----
2011-04-06

* Fixes missing RuntimeError::CODE

0.4.3
-----
2010-11-28

* Uses MessagePack::Unpacker#feed_each implemented on msgpack-0.4.4

0.4.2
-----
2010-08-28

* Fixes exception.rb

0.4.1
-----
2010-08-27

* Adds MultiFuture class
* New exception mechanism
* Rescues all errors on_readable not to stop event loop
* Future: doesn't wrap callback_handler but check on calling for backward compatibility
* Responder: adds a guard not to send results twice
* Session: adds call_apply and notify_apply
* Uses jeweler and Rakefile for packaging

0.4.0
-----
2010-05-28

* updates dispatch mechanism
* adds Session#call_apply and notify_apply
* Responder prevents sending results twice