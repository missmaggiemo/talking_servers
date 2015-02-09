class Message

  def initialize(sender, receiver, text, time_sent)
    @sender, @receiver, @text, @time_sent = sender, receiver, text, time_sent
    @time_received = nil
  end

  def to_s
    "#{@sender}:#{@text}:#{@time_sent}"
  end

  def ==(msg)
    @sender == msg.sender and @receiver == msg.receiver and @text == msg.text
  end

  def text
    @text
  end

  def text=(t)
    @text = t
  end

  def sender
    @sender
  end

  def sender=(p)
    @sender = p
  end

  def time_sent
    @time_sent
  end

  def time_sent=(t)
    @time_sent = t
  end

  def receiver
    @receiver
  end

  def receiver=(p)
    @receiver = p
  end

  def received!
    @time_received = Time.now
  end

  def received?
    !!@time_received
  end

  def time_received
    @time_received
  end

end