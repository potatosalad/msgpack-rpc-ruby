# encoding: utf-8

class MySpy
  def initialize
    @called = false
  end

  def call(*args)
    @called = true
    return nil
  end

  def called?
    !!@called
  end
end
