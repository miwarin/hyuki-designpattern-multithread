# coding: utf-8

#
# 『増補改訂版Java言語で学ぶデザインパターン入門マルチスレッド編』 http://www.hyuki.com/dp/dp2.html
# 
# Guarded Suspension - 用意できるまで、待っててね
#

require 'thread'
require 'monitor'

class Request
  def initialize(name)
    @name = name
  end
  
  def getName()
    return @name
  end
  
  def to_s()
    return "[ Request #{@name} ]"
  end
end

class RequestQueue
  def initialize()
    @lock = Monitor.new()
    @cond = @lock.new_cond
    @queue ||= []
  end
  
  def getRequest()
    @lock.synchronize {
      while @queue.empty? == true
        begin
          @cond.wait()
        rescue
        end
      end
      return @queue.pop()
    }
  end
  
  def putRequest(request)
    @lock.synchronize {
      @queue.push(request)
      @cond.broadcast()
    }
  end
end

class ServerThread < Thread
  def initialize(requestQueue, name, seed)
    @requestQueeu = requestQueue
    @random = Random.new(seed)
    
    block = Proc.new {
      0.upto(10) {|i|
        request = requestQueue.getRequest()
        puts "#{self} handles #{request}"
        begin
          sleep(random.rand(10))
        rescue
        end
      }
    }
    super(&block)
  end
end


class ClientThread < Thread
  def initialize(requestQueue, name, seed)
    @requestQueue = requestQueue
    @random = Random.new(seed)
    
    block = Proc.new {
      0.upto(10) {|i|
        request = Request.new("No. #{i}")
        puts "#{self} requests #{request}"
        @requestQueue.putRequest(request)
        begin
          sleep(random.rand(10))
        rescue
        end
      }
    }
    super(&block)
  end
end

def main(argv)
  th ||= []
  requestQueue = RequestQueue.new()
  th << ServerThread.new(requestQueue, "Bobby", 6535897)
  th << ClientThread.new(requestQueue, "Alice", 3141592)
  th.each {|t| t.join() }
end

main(ARGV)

=begin
ruby GuardedSuspension.rb
#<ClientThread:0x000000002fbde0> requests [ Request No. 0 ]
#<ClientThread:0x000000002fbde0> requests [ Request No. 1 ]
#<ServerThread:0x00000002abd608> handles [ Request No. 0 ]
#<ClientThread:0x000000002fbde0> requests [ Request No. 2 ]
#<ServerThread:0x00000002abd608> handles [ Request No. 1 ]
#<ClientThread:0x000000002fbde0> requests [ Request No. 3 ]
#<ServerThread:0x00000002abd608> handles [ Request No. 2 ]
#<ClientThread:0x000000002fbde0> requests [ Request No. 4 ]
#<ServerThread:0x00000002abd608> handles [ Request No. 3 ]
#<ClientThread:0x000000002fbde0> requests [ Request No. 5 ]
#<ServerThread:0x00000002abd608> handles [ Request No. 4 ]
#<ClientThread:0x000000002fbde0> requests [ Request No. 6 ]
#<ServerThread:0x00000002abd608> handles [ Request No. 5 ]
#<ClientThread:0x000000002fbde0> requests [ Request No. 7 ]
#<ServerThread:0x00000002abd608> handles [ Request No. 6 ]
#<ClientThread:0x000000002fbde0> requests [ Request No. 8 ]
#<ServerThread:0x00000002abd608> handles [ Request No. 7 ]
#<ClientThread:0x000000002fbde0> requests [ Request No. 9 ]
#<ServerThread:0x00000002abd608> handles [ Request No. 8 ]
#<ClientThread:0x000000002fbde0> requests [ Request No. 10 ]
#<ServerThread:0x00000002abd608> handles [ Request No. 9 ]
#<ServerThread:0x00000002abd608> handles [ Request No. 10 ]
=end



