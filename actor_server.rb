require 'thread'
require 'socket'
require 'set'
require_relative './message'
require_relative './actor'


class Server < Actor

  attr_reader :server_addresses, :port

  def initialize(port, server_addresses=[port])
    super(port)
    @server_addresses = Set.new(server_addresses)
  end

  def transition!(msg)
    p "#{port} received #{msg.text} from #{msg.sender} at #{msg.time_received}"
    if msg.text == 'Beat'
      self.send_message!(
        Message.new({sender: port, receiver: msg.sender, text: 'Ack'}))
    elsif msg.text == 'Ack'
      # Whatever Raft should do with an Ack.
    elsif msg.text == 'SendHeartbeats'
      self.send_heartbeats!
    elsif msg.text == 'Master?'
      # Whatever Raft should do with a request for master.
    end
  end

  def send_heartbeats!
    self.server_addresses.each do |address|
      self.send_message!(Message.new(port, address, 'Beat', Time.now))
    end
    self.set_timer!(2, Message.new({sender: port, receiver: port, text: 'SendHeartbeats'}))
  end

  private

  def server_ack(message)
    p "heartbeat #{self.port}"
  end  

  def server_broadcast(message)
    return if @received_messages[message.sender].include? message
    tell_everyone(message)
  end

  def tell_everyone(message)
    @server_addresses.each do |port|
      sending_message = Message.new(@port, port, message.text, Time.now)
      send_message(sending_message)
    end
  end

end
