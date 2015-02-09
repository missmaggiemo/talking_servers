require 'socket'
require_relative './actor'


$ports = [9000, 9001, 9002, 9003, 9004]
$actors = []
$threads = []

$ports.each do |port|
  $threads << Thread.new do
    actr = Actor.new(port)
    $actors << actr
    actr.set_actor_addresses($ports)
    actr.start_server
  end
end

$threads << Thread.new do
  $actors[0].send_first_message('hi', 9001)
end

$threads.each { |thr| thr.join }
