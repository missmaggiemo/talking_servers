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

  def send_first_message(text, address)
    sending_message = Message.new(@port, address, text, Time.now)
    send_message(sending_message)
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

  def send_message(message)
    p "#{@port} sending #{message.text} to #{message.receiver} at #{message.time_sent}"
    Thread.new do
      sock = TCPSocket.new 'localhost', message.receiver
      sock.puts message.to_s
      @sent_messages[message.receiver] += [message]
      sock.close
    end.join
  end

  def send_message_wrapper(text, address)
    return if address == @port or !@actor_addresses.include? address

    sending_message = Message.new(@port, address, text, Time.now)
    return if @sent_messages[sending_message.receiver].include? sending_message
    send_message(sending_message)
  end

  def tell_everyone(message)
    @actor_addresses.each { |port| send_message_wrapper(message.text, port) }
  end

end
