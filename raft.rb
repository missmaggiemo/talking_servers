require 'socket'

$ports = [9000, 9001, 9002, 9003, 9004]

class RaftServer

  def initialize(port_number)
    @port = port_number
  end

  def start
    p "Starting server on port #{@port}"
    server = TCPServer.new @port
    loop do
      client = server.accept
      message = client.gets.chomp
      p "#{message} on #{@port}"
      client.puts message
      client.close
      if message == 'master'
        self.try_to_become_master
      else
        self.send_message(9001, 'hi')
      end
    end
  end

  def try_to_become_master
    p 'try_to_become_master'
    $ports.each do |port|
      next if port == @port
      sock = TCPSocket.new 'localhost', port
      sock.puts 'Make me master'
      sock.close
    end
  end

  def send_message(port, message)
    p 'send_message'
    return if port == @port
    sock = TCPSocket.new 'localhost', port
    sock.puts message
    sock.close
    p 'message_sent'
  end

end

$threads = []

$ports.each do |port|
  $threads << Thread.new do
    RaftServer.new(port).start
  end
end

$threads.each { |thr| thr.join }
