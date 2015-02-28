require 'thread'
require 'socket'
require_relative './message'

class Actor

  attr_reader :port, :messages

  def initialize(port)
    @port = port
    @messages = Queue.new
    @threads = []
  end

  def start
    @threads << self.start_listening
    @threads << self.start_working
  end

  def join
    @threads.each { |thr| thr.join }
  end

  def start_listening
    tcp_server = TCPServer.new @port
    Thread.new do
      loop do
        client = tcp_server.accept
        @messages << Message.parse(client.gets.chomp).received!
        client.close
      end
    end
  end

  def start_working
    Thread.new do
      loop do
        message = @messages.shift
        transition!(message)
      end
    end
  end

  def transition!(msg)
    p "#{port} received #{msg.text} from #{msg.sender} at #{msg.time_received}"
    self.send(self.class.events[msg.text], msg)
  end

  def self.events
    @events ||= Hash.new
  end

  def self.set_transition(event_name, action_name)
    self.events[event_name] = action_name
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

