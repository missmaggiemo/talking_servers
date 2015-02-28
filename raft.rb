require_relative './actor_server'

Thread.abort_on_exception = true

$ports = [9000, 9001, 9002]
$servers = []

$ports.each do |port|
  srvr = Server.new(port, $ports)
  srvr.start
  $servers << srvr # race condition
end

p $ports
p $servers
$servers[0].send_heartbeats!


$servers.each { |srvr| srvr.join }


