require 'thread'
require 'socket'
require_relative './message'

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
    tcp_server = TCPServer.new @port
    Thread.new do
      loop do
        client = tcp_server.accept
        @messages << Message.new(JSON.parse(client.gets.chomp)).received!
        tcp_server.close
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

  def send_message!(message)
    sock = TCPSocket.new 'localhost', message.receiver
    sock.puts message.sent!.to_json
    sock.close
    p "#{@port} sending #{message.text} to #{message.receiver} at #{message.time_sent}"
  end

  def set_timer!(wait_time, msg)
    # wait_time is an integer of seconds to wait, msg is a message object to send if timer ends
    Thread.new do
      sleep(wait_time)
      @messages << msg.sent!.received!
    end
  end

end

# need to respond to different messages, e.g. vote for master

# transition map-- state, message?


