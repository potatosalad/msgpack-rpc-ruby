# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'msgpack/rpc/version'

Gem::Specification.new do |spec|
  spec.name          = "msgpack-rpc"
  spec.version       = MessagePack::RPC::VERSION
  spec.authors       = ["FURUHASHI Sadayuki"]
  spec.email         = ["frsyuki@users.sourceforge.jp"]
  spec.description   = %q{MessagePack-RPC, asynchronous RPC library using MessagePack}
  spec.summary       = %q{MessagePack-RPC, asynchronous RPC library using MessagePack}
  spec.homepage      = "http://msgpack.org/"
  spec.license       = "Apache License, Version 2.0"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "msgpack", "~> 0.5.5"
  spec.add_dependency "cool.io", "~> 1.2.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
