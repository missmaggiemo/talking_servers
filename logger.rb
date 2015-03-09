require 'thread'

class Logger

  @msg_queue = Queue.new

  def self.log(port, msg)
    @msg_queue << "#{port}: #{msg}"
  end

  def self.start
    Thread.new do
      loop do
        puts @msg_queue.shift
      end
    end
  end

end
