require 'thread'
require 'socket'
require_relative './server'

Thread.abort_on_exception = true

$ports = [9000, 9001, 9002]
$servers = []
$threads = []

$ports.each do |port|
  srvr = Server.new(port, $ports)
  $threads << srvr.start_listening_for_heartbeats
  $servers << srvr # race condition
end

p $ports
p $servers
server = $servers.shift
$threads << server.start_sending_heartbeats


$threads.each { |thr| thr.join }
