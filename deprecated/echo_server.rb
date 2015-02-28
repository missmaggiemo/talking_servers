require 'socket'

class EchoServer
  def initialize(port)
    @port = port
    @listeners = []
  end

  def start
    p "Hi #{@port}"
    @listeners << TCPServer.new(@port)
    # event reactor-- "This is how Node works"
    loop do
      arr = IO.select @listeners
      reader = arr[0][0] # IO.select returns an array of arrays... Please just give us the first thing.
      if reader.class == TCPServer
        p "TCPServer"
        @listeners << reader.accept
      else
        message = reader.gets
        reader.puts message
      end
    end
  end

end

EchoServer.new(9006).start



