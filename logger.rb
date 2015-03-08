require 'thread'

class Logger

  @msg_queue = Queue.new

  def self.log(msg)
    @msg_queue << msg
  end

  def self.start
    Thread.new do
      loop do
        p @msg_queue.shift
      end
    end
  end

end