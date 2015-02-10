require 'socket'
require 'set'
require_relative './message'


class Actor

  attr_reader :actor_addresses

  def initialize(port, actor_addresses=[port])
    @port = port
    @sent_messages = Hash.new { [] }
    @received_messages = Hash.new { [] }
    @actor_addresses = Set.new(actor_addresses)
  end

  def start_server
    p "Starting server on port #{@port}"
    server = TCPServer.new @port
    loop do
      client = server.accept
      sender, text, time_sent = client.gets.chomp.split(':')
      message = Message.new(sender, @port, text, time_sent)
      server_ack(message)
      client.close
    end
  end

  def send_first_message(text, address)
    sending_message = Message.new(@port, address, text, Time.now)
    send_message(sending_message)
  end


  private

  def server_ack(message)
    return if @received_messages[message.sender].include? message

    receive_message(message)
    tell_everyone(message)
  end

  def receive_message(message)
    message.received!
    p "#{@port} received #{message.text} from #{message.sender} at #{message.time_received}"
    self.actor_addresses.add(message.sender)
    @received_messages[message.sender] += [message]
  end

  def send_message(message)
    return if message.receiver == @port or !@actor_addresses.include? message.receiver
    return if @sent_messages[message.receiver].include? message

    p "#{@port} sending #{message.text} to #{message.receiver} at #{message.time_sent}"
    sock = TCPSocket.new 'localhost', message.receiver
    sock.puts message.to_s
    @sent_messages[message.receiver] += [message]
    sock.close
  end

  def tell_everyone(message)
    @actor_addresses.each do |port|
      sending_message = Message.new(@port, port, message.text, Time.now)
      send_message(sending_message)
    end
  end

end
