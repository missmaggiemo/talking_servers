require 'thread'
require 'socket'
require_relative './actor'

Thread.abort_on_exception = true

$ports = [9000, 9001]
$actors = Queue.new
$threads = []

$ports.each do |port|
  actr = Actor.new(port, $ports)
  $threads << actr.start_listening_for_heartbeats
  $actors << actr # race condition
end

$ports.length.times do
  actor = $actors.pop
  $threads << actor.start_sending_heartbeats
end

$threads.each { |thr| thr.join }
