require_relative './raft_actor'

Thread.abort_on_exception = true

$ports = [9000, 9001, 9002]
$servers = []

$ports.each do |port|
  srvr = RaftActor.new(port, $ports)
  srvr.start
  $servers << srvr # race condition
end

p $ports
p $servers
$servers[0].request_vote!


$servers.each { |srvr| srvr.join }


