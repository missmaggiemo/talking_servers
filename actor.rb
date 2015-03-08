require 'thread'
require 'socket'
require_relative './message'
require_relative './logger'

class Actor

  attr_reader :port, :messages, :timers

  def initialize(port)
    @port = port
    @messages = Queue.new
    @threads = []
    @timers = Hash.new 0
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
    Logger.log "#{port} received #{msg.text} from #{msg.sender} at #{msg.time_received}"
    unless self.class.events[msg.text]
      Logger.log "Ignore event #{msg.text}!"
      return
    end
    self.send(self.class.events[msg.text], msg)
  end

  def self.events
    @events ||= Hash.new
  end

  def self.set_transition(event_name, action_name)
    self.events[event_name] = action_name
  end

  def send_message!(message)
    sleep(rand() * 0.3)
    sock = TCPSocket.new 'localhost', message.receiver
    sock.puts message.sent!.to_json
    sock.close
    Logger.log "#{@port} sending #{message.text} to #{message.receiver} at #{message.time_sent}"
  end

  def set_timer!(wait_time, msg)
    # wait_time is an integer of seconds to wait, msg is a message object to send if timer ends
    expire_timer(msg.text)
    msg.data[:timer] = timers[msg.text]
    Thread.new do
      sleep(wait_time)
      @messages << msg.sent!.received!
    end
  end

  def expire_timer(name)
    timers[name] += 1
  end

end

