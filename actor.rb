require 'thread'
require 'socket'
require_relative './message'
require_relative './logger'

class Actor

  attr_reader :port, :state, :messages, :timers

  def initialize(port, state)
    @port, @state = port, state
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
    """
    Start listening for messages on the port that the actor was initialized on.
    """
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
    """
    Receive a message and react accordingly.
    """
    Thread.new do
      loop do
        message = @messages.shift
        transition!(message)
      end
    end
  end

  def transition!(msg)
    """
    React to a message, msg, if we've set a transition; ignore the event if we haven't set a
    transition. Also ignore expired events, and raise an error if the actor isn't in the right
    state for that event.
    """
    if !self.class.events[msg.text]
      return
    elsif self.timers.has_key?(msg.text) && self.timers[msg.text] != msg.data[:timer]
      return
    end

    Logger.log(port, "received #{msg.text} from #{msg.sender}")

    unless self.class.event_states[msg.text].nil? or @state[:name] == self.class.event_states[msg.text]
      raise "Incorrect State"
    end
    self.send(self.class.events[msg.text], msg)
  end

  def self.events
    @events ||= Hash.new
  end

  def self.event_states
    @event_states ||= Hash.new
  end

  def self.set_transition(event_name, action_name, state_name=nil)
    """
    Set a transition method, action_name, for a given event, event_name. Optionally, set a required
    state for that event.
    """
    self.events[event_name] = action_name
    self.event_states[event_name] = state_name
  end

  def send_message!(message)
    sleep(rand() * 0.3)
    sock = TCPSocket.new 'localhost', message.receiver
    sock.puts message.sent!.to_json
    sock.close
  end

  def set_timer!(wait_time, msg)
    """
    Set a wait time, wait_time, of seconds to wait before sending a particular message.
    """
    expire_timer!(msg.text)
    msg.data[:timer] = timers[msg.text]
    Thread.new do
      sleep(wait_time)
      @messages << msg.sent!.received!
    end
  end

  def expire_timer!(name)
    timers[name] += 1
  end

end
