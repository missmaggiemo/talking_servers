require 'json'

class Message

  attr_reader :time_received
  attr_accessor :sender, :receiver, :text, :data, :time_sent

  def initialize(sender, receiver, text, data={}, time_sent=Time.now)
    self.sender, self.receiver, self.text, self.data, self.time_sent =
      sender, receiver, text, data, time_sent

    @time_received = nil
  end

  def self.parse(str)
    msg_hash = JSON.parse(str)
    self.new(msg_hash['sender'], msg_hash['receiver'], msg_hash['text'], msg_hash['data'], msg_hash['time_sent'])
  end


  def to_json
    {sender: sender, receiver: receiver, text: text, data: data, time_sent: time_sent}.to_json
  end

  def ==(msg)
    sender == msg.sender and receiver == msg.receiver and text == msg.text
  end

  def received!
    @time_received = Time.now
    return self
  end

  def received?
    !!time_received
  end

  def sent!
    @time_sent = Time.now
    return self
  end

end