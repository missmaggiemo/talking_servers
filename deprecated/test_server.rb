require 'socket'

p 'Server on 9005'
server = TCPServer.new 9005
client = server.accept
message = client.gets.chomp
client.puts message
p message