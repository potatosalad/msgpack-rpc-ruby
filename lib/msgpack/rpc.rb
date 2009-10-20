#
# MessagePack-RPC for Ruby
#
# Copyright (C) 2009 FURUHASHI Sadayuki
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
require 'msgpack'
require 'rev'

module MessagePack
module RPC


class Error < StandardError
end

class RPCError < Error
	def initialize(msg)
		super(msg)
	end
end

class RemoteError < RPCError
	def initialize(msg, result = nil)
		super(msg)
		@result = result
	end
	attr_reader :result
end

class TimeoutError < Error
	def initialize
		super("request timed out")
	end
end


class Responder
	def initialize(socket, msgid)
		@socket = socket
		@msgid = msgid
	end

	def result(retval, err = nil)
		@socket.send_response(@msgid, retval, err)
	end

	def error(err)
		result(nil, err)
	end
end


REQUEST  = 0
RESPONSE = 1
NOTIFY   = 2


module RPCSocket
	def session=(s)
		@session = s
		s.add_socket(self)
	end

	def on_message(msg)
		case msg[0]
		when REQUEST
			on_request(msg[1], msg[2], msg[3])
		when RESPONSE
			on_response(msg[1], msg[2], msg[3])
		when NOTIFY
			on_notify(msg[1], msg[2])
		else
			raise RPCError.new("unknown message type #{msg[0]}")
		end
	end

	def on_close
		return unless @session
		@session.on_close(self)
		@session = nil
	rescue
		nil
	end

	def on_request(msgid, method, param)
		return unless @session
		@session.on_request(method, param, Responder.new(self,msgid))
	end

	def on_notify(method, param)
		return unless @session
		@session.on_notify(method, param)
	end

	def on_response(msgid, error, result)
		return unless @session
		@session.on_response(msgid, error, result)
	end

	def send_request(msgid, method, param)
		send_message [REQUEST, msgid, method, param]
	end

	def send_response(msgid, result, error)
		send_message [RESPONSE, msgid, error, result]
	end

	def send_notify(method, param)
		send_message [NOTIFY, method, param]
	end
end


class RevSocket < ::Rev::TCPSocket
	include RPCSocket

	def initialize(*args)
		@buffer = ''
		@nread = 0
		@mpac = MessagePack::Unpacker.new
		super
	end

	def on_read(data)
		@buffer << data

		while true
			@nread = @mpac.execute(@buffer, @nread)

			if @mpac.finished?
				msg = @mpac.data

				@mpac.reset
				@buffer.slice!(0, @nread)
				@nread = 0

				on_message(msg)  # RPCSocket#on_message

				next unless @buffer.empty?
			end

			break
		end
	end

	def send_message(msg)
		write msg.to_msgpack
	end
end


class ClientSession

	class BasicRequest
		def initialize(session, loop)
			@session = session
			@timeout = session.timeout
			@loop = loop
		end
		attr_reader :loop

		def call(err, res)
			@session = nil
		end

		def join
			while @session
				@loop.run_once
			end
			self
		end

		def step_timeout
			if @timeout < 1
				true
			else
				@timeout -= 1
				false
			end
		end
	end

	class AsyncRequest < BasicRequest
		def initialize(session, loop)
			super(session, loop)
			@error  = nil
			@result = nil
		end
		attr_accessor :result, :error

		def call(err, res)
			@error  = err
			@result = res
			@session = nil
		end
	end

	class CallbackRequest < BasicRequest
		def initialize(session, loop, block)
			super(session, loop)
			@block = block
		end

		def call(err, res)
			@block.call(err, res)
		end
	end


	def initialize(loop)
		@sock = nil
		@reqtable = {}
		@seqid = 0
		@loop = loop
		@timeout = 60    # FIXME default timeout time
	end
	attr_accessor :timeout

	def add_socket(sock)
		@sock = sock
	end

	def send(method, *args)
		send_real(method, args, AsyncRequest.new(self,@loop))
	end

	def callback(method, *args, &block)
		send_real(method, args, CallbackRequest.new(self,@loop,block))
	end

	def call(method, *args)
		req = send(method, *args)
		req.join
		if req.error
			raise TimeoutError.new if req.error == :TimeoutError
			raise RemoteError.new(req.error, req.result)
		end
		req.result
	end

	def notify(method, *args)
		notify_real(method, args)
	end


	def on_response(msgid, error, result)
		if req = @reqtable.delete(msgid)
			req.call error, result
		end
	end

	def on_notify(method, param)
		raise RPCError.new("unexpected notify message")
	end

	def on_request(method, param, res)
		raise RPCError.new("unexpected request message")
	end

	def on_close(sock)
		@sock = nil
	end

	def close
		@sock.close if @sock
	end


	def step_timeout
		reqs = []
		@reqtable.reject! {|msgid, req|
			if req.step_timeout
				reqs.push req
			end
		}
		reqs.each {|req| req.call :TimeoutError, nil }
	end

	private
	def send_real(method, param, req)
		method = method.to_s unless method.is_a?(Integer)
		msgid = @seqid
		@seqid += 1; if @seqid >= 1<<31 then @seqid = 0 end
		@sock.send_request msgid, method, param
		@reqtable[msgid] = req
	end

	def notify_real(method, param)
		method = method.to_s unless method.is_a?(Integer)
		@sock.send_notify method, param
		nil
	end
end


class AsyncResult
	def initialize
		@responder = nil
		@sent = false
	end

	def result(retval, err = nil)
		unless @sent
			if @responder
				@responder.result(retval, err)
			else
				@result = [retval, err]
			end
			@sent = true
		end
		nil
	end

	def error(err)
		result(nil, err)
		nil
	end

	def responder=(res)
		@responder = res
		if @sent && @result
			@responder.result(*@result)
			@result = nil
		end
	end
end


class ServerSession
	def initialize(obj, accept = obj.public_methods)
		@obj = obj
		@accept = accept.map {|m| m.is_a?(Integer) ? m : m.to_s}
	end

	def add_socket(sock)
		# do nothing
	end

	def on_request(method, param, res)
		begin
			result = forward_method(method, param)
		rescue
			res.error($!.to_s)
			return
		end
		if result.is_a?(AsyncResult)
			result.responder = res
		else
			res.result(result)
		end
	end

	def on_notify(method, param)
		forward_method(method, param)
	rescue
	end

	def on_response(msgid, error, result)
		raise RPCError.new("unexpected response message")
	end

	def on_close(sock)
		# do nothing
		@sock = nil
	end

	private
	def forward_method(method, param)
		unless @accept.include?(method)
			raise NoMethodError, "method `#{method}' is not accepted"
		end
		@obj.send(method, *param)
	end
end

Loop = ::Rev::Loop

module LoopUtil
	attr_reader :loop

	class Timer < Rev::TimerWatcher
		def initialize(interval, repeating, &block)
			@block = block
			super(interval, repeating)
		end
		def on_timer
			@block.call
		end
	end

	def start_timer(interval, repeating, &block)
		@loop.attach Timer.new(interval, repeating, &block)
	end

	def run
		@loop.run
	end

	def stop
		@loop.stop
		# attach dummy timer
		@loop.attach Rev::TimerWatcher.new(0, false)
		nil
	end
end


class Client
	def initialize(host, port, loop = Loop.new)
		@loop = loop
		@host = host
		@port = port
		@rsock = RevSocket.connect(host, port)
		@s = ClientSession.new(loop)
		@rsock.session = @s
		loop.attach(@rsock)
		@timer = Timer.new(1, true) { @s.step_timeout }
		loop.attach(@timer)
	end
	attr_reader :host, :port

	def close
		@timer.detach
		@rsock.detach
		@s.close
		nil
	end

	def send(method, *args)
		@s.send(method, *args)
	end

	def callback(method, *args, &block)
		@s.callback(method, *args, &block)
	end

	def call(method, *args)
		@s.call(method, *args)
	end

	def notify(method, *args)
		@s.notify(method, *args)
	end

	def timeout
		@s.timeout
	end

	def timeout=(time)
		@s.timeout = time
	end

	include LoopUtil
end


class Server
	class Socket < RevSocket
		def initialize(*args)
			accept = args.pop
			obj = args.pop
			self.session = ServerSession.new(obj, accept)
			super(*args)
		end
	end

	def initialize(loop = Loop.new)
		@loop = loop
		@socks = []
	end

	def listen(host, port, obj, accept = obj.public_methods)
		lsock = ::Rev::TCPServer.new(host, port, Server::Socket, obj, accept)
		@socks.push lsock
		@loop.attach(lsock)
	end

	def close
		@socks.reject! {|lsock|
			lsock.detach
			lsock.close
			true
		}
		nil
	end

	include LoopUtil
end


end  # module RPC
end  # module MessagePack

