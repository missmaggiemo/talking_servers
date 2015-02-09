require 'socket'
require_relative './message'


class Actor

  def initialize(port, actor_addresses=[port])
    @port = port
    @sent_messages = Hash.new { [] }
    @received_messages = Hash.new { [] }
    @actor_addresses = actor_addresses
  end

  def start_server
    p "Starting server on port #{@port}"
    Thread.new do
      server = TCPServer.new @port
      loop do
        client = server.accept
        sender, text, time_sent = client.gets.chomp.split(':')
        message = Message.new(sender, @port, text, time_sent)
        server_ack(message)
        client.close
      end
    end.join
  end

  def add_actor_address(port)
    @actor_addresses << port unless @actor_addresses.include? port
    @actor_addresses
  end

  def set_actor_addresses(actor_address_list)
    (@actor_addresses += actor_address_list).uniq!
    @actor_addresses
  end

  def actor_addresses
    @actor_addresses
  end


  private

  def server_ack(message)
    receive_message(message)
    return if @received_messages[message.sender].include? message

    @received_messages[message.sender] += [message]
    tell_everyone(message)
  end

  def receive_message(message)
    message.received!
    p "#{@port} received #{message.text} from #{message.sender} at #{message.time_received}"
    self.add_actor_address(message.sender) unless @received_messages[message.sender].length
  end

  def send_message(received_message, address)
    return if address == @port or !@actor_addresses.include? address

    sending_message = Message.new(@port, address, received_message.text, Time.now)
    return if @sent_messages[sending_message.receiver].include? sending_message

    p "#{@port} sending #{received_message.text} to #{address} at #{sending_message.time_sent}"
    Thread.new do
      sock = TCPSocket.new 'localhost', sending_message.receiver
      sock.puts sending_message.to_s
      @sent_messages[sending_message.receiver] += [sending_message]
      sock.close
    end.join
  end

  def tell_everyone(message)
    @actor_addresses.each { |port| send_message(message, port) }
  end

end


$ports = [9000, 9001, 9002, 9003, 9004]
$threads = []

$ports.each do |port|
  $threads << Thread.new do
    actr = Actor.new(port)
    actr.set_actor_addresses($ports)
    actr.start_server
  end
end

$threads.each { |thr| thr.join }
