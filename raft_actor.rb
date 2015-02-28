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
    @round = 0
  end

  def send_heartbeats!(msg=nil)
    self.server_addresses.each do |address|
      next if address == port
      self.send_message!(Message.new(port, address, 'Beat'))
    end
    self.set_timer!(2, Message.new(port, port, 'SendHeartbeats'))
  end

  def send_ack!(msg)
    self.send_message!(
      Message.new(port, msg.sender, 'Ack'))
  end

  def receive_ack!(msg)
    p "Received Ack!"
  end

  def request_vote!(msg=nil)
    @round += 1
    self.server_addresses.each do |address|
      next if address == port
      self.send_message!(Message.new(port, address, 'RequestVote', {round: @round}))
    end
    @num_votes = 1
  end

  def receive_vote!(msg)
    p "Vote received!"
    @num_votes += 1
    if @num_votes >= (@server_addresses.length / 2) + 1
      # We should only get elected once... Check here.
      p "#{port} elected master!"
      send_heartbeats!
    end
  end

  def receive_vote_request!(msg)
    if @round < msg.data['round']
      self.send_message!(
        Message.new(port, msg.sender, 'Vote'))
      @round = msg.data['round']
    else
      p "Ignoring vote request"
    end
  end

end
