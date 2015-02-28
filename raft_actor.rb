require 'thread'
require 'socket'
require 'set'
require_relative './message'
require_relative './actor'


class RaftActor < Actor

  attr_reader :server_addresses, :port

  set_transition 'Beat', :send_ack!
  set_transition 'SendHeartbeats', :send_heartbeats!
  set_transition 'Ack', :receive_ack!

  def initialize(port, server_addresses=[port])
    super(port)
    @server_addresses = Set.new(server_addresses)
  end

  def send_heartbeats!(msg=nil)
    self.server_addresses.each do |address|
      self.send_message!(Message.new(port, address, 'Beat', Time.now))
    end
    self.set_timer!(2, Message.new(port, port, 'SendHeartbeats', Time.now))
  end

  def send_ack!(msg)
    self.send_message!(
      Message.new(port, msg.sender, 'Ack', Time.now))
  end

  def receive_ack!(msg)
    p "Received Ack!"
  end

end
