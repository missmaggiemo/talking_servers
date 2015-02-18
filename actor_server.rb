require 'thread'
require 'socket'
require 'set'
require_relative './message'
require_relative './actor'


class Server

  attr_reader :server_addresses, :port

  def initialize(port, server_addresses=[port])
    @port = port
    @sent_messages = Hash.new { [] }
    @received_messages = Hash.new { [] }
    @server_addresses = Set.new(server_addresses)
    @mutex = Mutex.new
  end

  def start_server
    p "Starting server on port #{@port}"
    server = TCPServer.new @port
    loop do
      client = server.accept
      sender, text, time_sent = client.gets.chomp.split(':')
      message = Message.new(sender, @port, text, time_sent)
      server_broadcast(message)
      client.close
    end
  end

  def send_first_message(text, address)
    sending_message = Message.new(@port, address, text, Time.now)
    send_message(sending_message)
  end

  def start_sending_heartbeats
    Thread.new do
      loop do
        self.server_addresses.each do |address|
          send_message(Message.new(@port, address, 'Beat', Time.now))
        end
        sleep(2)
      end
    end
  end

  def start_listening_for_heartbeats
    server = TCPServer.new @port
    Thread.new do
      loop do
        client = server.accept
        sender, text, time_sent = client.gets.chomp.split(':')
        p "#{@port} sees heartbeat from #{sender} at #{Time.now}"
        client.close
      end
    end
  end


  private

  def server_ack(message)
    p "heartbeat #{self.port}"
  end  

  def server_broadcast(message)
    return if @received_messages[message.sender].include? message

    process_message(message)
    tell_everyone(message)
  end

  def process_message(message)
    @mutex.synchronize do
      message.received!
      p "#{@port} received #{message.text} from #{message.sender} at #{message.time_received}"
      self.server_addresses.add(message.sender)
      @received_messages[message.sender] += [message]
    end
  end

  def send_message(message)
    @mutex.synchronize do
      return if message.receiver == @port or !@server_addresses.include? message.receiver

      p "#{@port} sending #{message.text} to #{message.receiver} at #{message.time_sent}"
      sock = TCPSocket.new 'localhost', message.receiver
      sock.puts message.to_s
      @sent_messages[message.receiver] += [message]
      sock.close
    end
  end

  def tell_everyone(message)
    @server_addresses.each do |port|
      sending_message = Message.new(@port, port, message.text, Time.now)
      send_message(sending_message)
    end
  end

end
