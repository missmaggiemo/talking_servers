require 'thread'
require 'socket'

class Actor

  attr_reader :port, :messages

  def initialize(port)
    @port = port
    @messages = Queue.new
  end

  def start
    self.start_listening
    self.start_working
  end

  def start_listening
    server = TCPServer.new @port
    Thread.new do
      loop do
        client = server.accept
        @messages << client.gets.chomp
        server.close
      end
    end
  end

  def start_working
    Thread.new do
      message = @messages.shift
    end
  end

  def transition!(msg)
    raise Error
  end

end

# need to respond to different messages, e.g. vote for master

# transition map-- state, message?


