require 'thread'
require 'socket'
require_relative './actor'

Thread.abort_on_exception = true

$ports = [9000, 9001]
$actors = Queue.new
$threads = []

$ports.each do |port|
  $threads << Thread.new do
    sleep(1)
    actr = Actor.new(port)
    $actors << actr
    actr.actor_addresses.merge($ports)
    actr.start_server
  end
end

$threads << Thread.new do
  $ports.length.times do
    receip = $actors.pop
    if receip.port != 9001
      receip.send_first_message('hi', 9001)
      break
    end
  end
end

$threads.each { |thr| thr.join }
