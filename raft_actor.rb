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
  set_transition 'Beat', :receive_beat!

  def initialize(port, server_addresses=[port])
    super(port)
    @server_addresses = Set.new(server_addresses)
    @state = {name: :follower, round: 0}
  end

  def send_heartbeats!(msg)
    self.server_addresses.each do |address|
      next if address == port
      self.send_message!(Message.new(port, address, 'Beat', {round: state[:round]}))
    end
    self.set_timer!(2, Message.new(port, port, 'SendHeartbeats'))
  end

  def receive_beat!(msg)
    return unless msg.data[:round] >= state[:round]
    @state = {name: :follower, round: msg.data[:round]}
    expire_timer!('SendHeartbeats')
    set_timer!(4, Message.new(port, port, 'StartElection'))
  end

  def request_vote!(msg)
    @state = {name: :requested_vote, round: state[:round] + 1, num_votes: 1}
    expire_timer!('SendHeartbeats')
    set_timer!(4, Message.new(port, port, 'StartElection'))

    self.server_addresses.each do |address|
      next if address == port
      self.send_message!(Message.new(port, address, 'RequestVote', {round: state[:round]}))
    end
  end

  def receive_vote!(msg)
    return unless state[:name] == :requested_vote and state[:round] == msg.data[:round]

    @state[:num_votes] += 1
    if state[:num_votes] >= (@server_addresses.length / 2) + 1
      @state = {name: :master, round: state[:round]}
      Logger.log "#{port}: I was elected master!"
      expire_timer!('StartElection')
      set_timer!(0, Message.new(port, port, 'SendHeartbeats'))
    end
  end

  def receive_vote_request!(msg)
    if state[:round] < msg.data[:round]
      self.send_message!(
        Message.new(port, msg.sender, 'Vote', {round: msg.data[:round]}))
      @state = {name: :follower, round: msg.data[:round]}
      expire_timer!('SendHeartbeats')
      set_timer!(4, Message.new(port, port, 'StartElection'))
    else
      # Logger.log "Ignoring (old) vote request"
    end
  end

end
