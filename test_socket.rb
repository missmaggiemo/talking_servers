require 'socket'

p 'Socket on 9005'
sock = TCPSocket.new 'localhost', 9005
sock.puts "Socket says 'Hi' on 9005"
sock.close