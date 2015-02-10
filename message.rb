class Message

  attr_reader :time_received
  attr_accessor :sender, :receiver, :text, :time_sent

  def initialize(sender, receiver, text, time_sent)
    self.sender, self.receiver, self.text, self.time_sent = sender, receiver, text, time_sent
    @time_received = nil
  end

  def to_s
    "#{@sender}:#{@text}:#{@time_sent}"
  end

  def ==(msg)
    sender == msg.sender and receiver == msg.receiver and text == msg.text
  end

  def received!
    @time_received = Time.now
  end

  def received?
    !!time_received
  end

end