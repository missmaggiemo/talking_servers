require 'thread'
require 'socket'
require 'set'
require_relative './message'
require_relative './actor'
require_relative './logger'


class RaftActor < Actor

  attr_reader :server_addresses, :port, :state

  set_transition 'SendHeartbeats', :send_heartbeats!
  set_transition 'Vote', :receive_vote!
  set_transition 'RequestVote', :receive_vote_request!
  set_transition 'StartElection', :request_vote!

  def initialize(port, server_addresses=[port])
    super(port)
    @server_addresses = Set.new(server_addresses)
    @state = {name: 'follower', round: 0}
  end

  def send_heartbeats!(msg)
    return unless msg.data[:timer] == timers[msg.text]

    self.server_addresses.each do |address|
      next if address == port
      self.send_message!(Message.new(port, address, 'Beat'))
    end
    self.set_timer!(2, Message.new(port, port, 'SendHeartbeats'))
  end

  def request_vote!(msg=nil)
    @state = {name: 'requested_vote', round: state[:round] + 1, num_votes: 1}
    self.server_addresses.each do |address|
      next if address == port
      self.send_message!(Message.new(port, address, 'RequestVote', {round: state[:round]}))
    end
  end

  def receive_vote!(msg)
    Logger.log "Vote received!"
    return unless state[:name] == 'requested_vote' and state[:round] == msg.data['round']
    @state[:num_votes] += 1
    if state[:num_votes] >= (@server_addresses.length / 2) + 1
      @state = {name: 'master', round: state[:round]}
      Logger.log "#{port} elected master!"
      set_timer!(0, Message.new(port, port, 'SendHeartbeats'))
    end
  end

  def receive_vote_request!(msg)
    Logger.log "#{port} Our round: #{state[:round]}, Data round: #{msg.data['round']}"
    if state[:round] < msg.data['round']
      self.send_message!(
        Message.new(port, msg.sender, 'Vote', {round: msg.data['round']}))
      @state = {name: 'follower', round: msg.data['round']}
    else
      Logger.log "Ignoring (old) vote request"
    end
  end

end
