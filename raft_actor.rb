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
  set_transition 'Vote', :receive_vote!
  set_transition 'RequestVote', :receive_vote_request!

  def initialize(port, server_addresses=[port])
    super(port)
    @server_addresses = Set.new(server_addresses)
    @num_votes = 0
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

  def request_vote!(msg=nil)
    self.server_addresses.each do |address|
      self.send_message!(Message.new(port, address, 'RequestVote', Time.now))
    end
    @num_votes = 0
  end

  def receive_vote!(msg)
    p "Vote received!"
    @num_votes += 1
    if @num_votes >= (@server_addresses.length / 2) + 1
      p "#{port} elected master!"
      send_heartbeats!
    end
  end

  def receive_vote_request!(msg)
    self.send_message!(
      Message.new(port, msg.sender, 'Vote', Time.now))
  end

end
