require 'thread'
require 'socket'
require 'set'
require_relative './message'
require_relative './actor'
require_relative './logger'


class RaftActor < Actor

  attr_reader :server_addresses, :port

  set_transition 'SendHeartbeats', :send_heartbeats!
  set_transition 'Vote', :receive_vote!
  set_transition 'RequestVote', :receive_vote_request!
  set_transition 'StartElection', :request_vote!

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

  def request_vote!(msg=nil)
    @round += 1
    self.server_addresses.each do |address|
      next if address == port
      self.send_message!(Message.new(port, address, 'RequestVote', {round: @round}))
    end
    @num_votes = 1
  end

  def receive_vote!(msg)
    Logger.log "Vote received!"
    @num_votes += 1
    if @num_votes >= (@server_addresses.length / 2) + 1
      # We should only get elected once... Check here.
      Logger.log "#{port} elected master!"
      send_heartbeats!
    end
  end

  def receive_vote_request!(msg)
    Logger.log "#{port} Our round: #{@round}, Data round: #{msg.data['round']}"
    if @round < msg.data['round']
      self.send_message!(
        Message.new(port, msg.sender, 'Vote'))
      @round = msg.data['round']
    else
      Logger.log "Ignoring (old) vote request"
    end
  end

end
