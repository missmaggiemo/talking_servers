require 'thread'
require 'socket'
require 'set'
require_relative './message'
require_relative './actor'
require_relative './logger'


class RaftActor < Actor

  attr_reader :server_addresses

  set_transition 'SendHeartbeats', :send_heartbeats!, :master
  set_transition 'Vote', :receive_vote!
  set_transition 'RequestVote', :receive_vote_request!, :follower
  set_transition 'StartElection', :request_vote!, :follower
  set_transition 'Beat', :receive_beat!

  def initialize(port, server_addresses=[port])
    super(port, {name: :follower, round: 0})
    @server_addresses = Set.new(server_addresses)
  end

  def send_heartbeats!(msg)
    """
    Send a heartbeat to every port on our list of ports.
    """
    self.server_addresses.each do |address|
      next if address == port
      self.send_message!(Message.new(port, address, 'Beat', {round: state[:round]}))
    end
    self.set_timer!(2, Message.new(port, port, 'SendHeartbeats'))
  end

  def receive_beat!(msg)
    """
    Receive a heartbeat from the master node. Ignore beat if our round is more recent that the
    round from the message, msg.
    """
    return unless msg.data[:round] >= state[:round]
    @state = {name: :follower, round: msg.data[:round]}
    expire_timer!('SendHeartbeats')
    set_timer!(4, Message.new(port, port, 'StartElection'))
  end

  def request_vote!(msg)
    """
    Request a vote for master state and increment our round.
    """
    @state = {name: :requested_vote, round: state[:round] + 1, num_votes: 1}
    expire_timer!('SendHeartbeats')
    set_timer!(4, Message.new(port, port, 'StartElection'))

    self.server_addresses.each do |address|
      next if address == port
      self.send_message!(Message.new(port, address, 'RequestVote', {round: state[:round]}))
    end
  end

  def receive_vote!(msg)
    """
    Receive a vote if our round matches the round in message, msg. Otherwise, do nothing.
    """
    return unless state[:name] == :requested_vote and state[:round] == msg.data[:round]

    @state[:num_votes] += 1
    if state[:num_votes] >= (@server_addresses.length / 2) + 1
      @state = {name: :master, round: state[:round]}
      Logger.log(port, "I was elected master!")
      expire_timer!('StartElection')
      set_timer!(0, Message.new(port, port, 'SendHeartbeats'))
    end
  end

  def receive_vote_request!(msg)
    """
    Vote for a new leader if our round is out of date. Otherwise, ignore the message, msg.
    """
    if state[:round] < msg.data[:round]
      self.send_message!(
        Message.new(port, msg.sender, 'Vote', {round: msg.data[:round]}))
      @state = {name: :follower, round: msg.data[:round]}
      expire_timer!('SendHeartbeats')
      set_timer!(4, Message.new(port, port, 'StartElection'))
    end
  end

end
