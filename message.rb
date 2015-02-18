require 'json'

class Message

  attr_reader :time_received
  attr_accessor :sender, :receiver, :text, :time_sent

  def initialize(options)
    self.sender, self.receiver, self.text, self.time_sent = 
      options['sender'], options['receiver'], options['text'], options['time_sent']

    @time_received = nil
  end

  def parse(str)
    # class method to parse JSON, etc. and extract important info!
  end


  def to_json
    {sender: sender, receiver: receiver, text: text, time_sent: time_sent}.to_json
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