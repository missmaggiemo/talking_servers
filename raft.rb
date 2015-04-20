require 'optparse'
require_relative './message'
require_relative './raft_actor'
require_relative './logger'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ./raft.rb [options]"
  opts.on('-p', '--ports PORTS', 'Comma-separarted list of ports') do |v|
    options[:ports] = v.split(',')
  end
end.parse!


Thread.abort_on_exception = true
Logger.start

$ports = options[:ports] ? options[:ports] : [9000, 9001, 9002, 9003, 9004]
first_port = $ports[0]
$servers = []

$ports.each do |port|
  srvr = RaftActor.new(port, $ports)
  srvr.start
  $servers << srvr
end

sleep(1)  # give servers time to start-- this is a hack
$servers[0].set_timer!(0, Message.new(first_port, first_port, 'StartElection'))

# testing the ability to kill a master
loop do
  gets
  $servers[0].expire_timer!('SendHeartbeats')
end

$servers.each { |srvr| srvr.join }
