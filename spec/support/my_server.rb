# encoding: utf-8

class MyServer
  @port = 65500
  @sock = 0
  attr_accessor :port

  def initialize(svr)
    @svr = svr
  end

  def hello
    "ok"
  end

  def sum(a, b)
    a + b
  end

  def exception
    raise "raised"
  end

  def async
    as = MessagePack::RPC::AsyncResult.new
    @svr.start_timer(1, false) do
      as.result "async"
    end
    as
  end

  def async_exception
    as = MessagePack::RPC::AsyncResult.new
    @svr.start_timer(1, false) do
      as.error "async"
    end
    as
  end

  def self.next_port
    @port += 1
    if @port >= 65535
      @port = 65500
    end
    @port
  end

  def self.port
    @port
  end

  def self.next_sock
    @sock += 1
    sock
  end

  def self.sock
    tmppath = File.expand_path('../../../tmp', __FILE__)
    FileUtils.mkpath(tmppath) if not File.directory?(tmppath)
    socket = File.join(tmppath, "test#{@sock}.sock")
    if File.exist?(socket)
      FileUtils.rm(socket)
    end
    return socket
  end

  private

  def hidden
  end
end
