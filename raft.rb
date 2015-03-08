require_relative './message'
require_relative './raft_actor'
require_relative './logger'

Thread.abort_on_exception = true
Logger.start

$ports = [9000, 9001, 9002]
$servers = []

$ports.each do |port|
  srvr = RaftActor.new(port, $ports)
  srvr.start
  $servers << srvr
end

Logger.log $ports
Logger.log $servers
sleep(1)  # give servers time to start-- this is a hack
$servers[0].messages << Message.new(9000, 9000, 'StartElection').received!
$servers[1].messages << Message.new(9001, 9001, 'StartElection').received!

$servers.each { |srvr| srvr.join }


