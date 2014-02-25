# coding: utf-8

#
# 『増補改訂版Java言語で学ぶデザインパターン入門マルチスレッド編』 http://www.hyuki.com/dp/dp2.html
# 
# Worker Thread - 仕事が来るまで待ち、仕事が来たら働く
#

require 'thread'
require 'monitor'

MAX_REQUEST = 100

class Channel
  def initialize(threads)
    @lock = Monitor.new()
    @cond = @lock.new_cond()
    @requestQueue = Array.new(MAX_REQUEST)
    @head = 0;    # 次にtakeRequestする場所
    @tail = 0;    # 次にputRequestする場所
    @count = 0;   # Requestの数
    @threadPool = Array.new(threads)
  end
  
  def startWorkers()
    # join() するとブロックするのでやってはいけない
    0.upto(@threadPool.length - 1) {|i|
      @threadPool[i] = WorkerThread.new("Worker-#{i}", self)
    }
  end
  
  def putRequest(request)
    @lock.synchronize {
      while (@count >= @requestQueue.length)
        begin
          @cond.wait()
        rescue => ex
          puts ex
        end
      end
      @requestQueue[@tail] = request
      @tail = (@tail + 1) % @requestQueue.length
      @count += 1
      @cond.broadcast()
    }
  end

  def takeRequest()
    @lock.synchronize {
      while (@count <= 0)
        begin
          @cond.wait();
        rescue => ex
          puts ex
        end
      end
      request = @requestQueue[@head]
      @head = (@head + 1) % @requestQueue.length;
      @count -= 1
      @cond.broadcast()
      return request
    }
  end
end

class Request
  def initialize(name, number)
    @name = name      # 依頼者
    @number = number  # リクエストの番号
  end
  
  def execute()
    puts "#{Thread.current} executes #{to_s}"
    begin
      sleep(0.1)
    rescue => ex
      puts ex
    end
  end
  
  def to_s()
    return "[ Request from #{@name} No. #{@number} ]"
  end
  
end

class ClientThread < Thread
  def initialize(name, channel)
    @channel = channel
    @name = name
    
    block = Proc.new {
      begin
        i = 0
        while true
          request = Request.new(@name, i);
          @channel.putRequest(request)
          sleep(0.1)
          i += 1
        end
      rescue => ex
        puts ex
      end
      
    }
    super(&block)
  end
end

class WorkerThread < Thread
  def initialize(name, channel)
    @channel = channel
    
    block = Proc.new {
      while true
        request = @channel.takeRequest()
        request.execute()
      end
    }
    super(&block)
  end
end

def main(argv)
  th ||= []
  channel = Channel.new(5);   # ワーカースレッドの個数
  channel.startWorkers()
  th << ClientThread.new("Alice", channel)
  th << ClientThread.new("Bobby", channel)
  th << ClientThread.new("Chris", channel)
  th.each {|t| t.join() }
end

main(ARGV)


=begin
>ruby WorkerThread.rb
#<WorkerThread:0x00000002bc7760> executes [ Request from Alice No. 0 ]
#<WorkerThread:0x0000000031bde8> executes [ Request from Bobby No. 0 ]
#<WorkerThread:0x0000000031bb18> executes [ Request from Chris No. 0 ]
#<WorkerThread:0x0000000031b690> executes [ Request from Chris No. 1 ]
#<WorkerThread:0x00000002bc7760> executes [ Request from Alice No. 1 ]
#<WorkerThread:0x0000000031bb18> executes [ Request from Bobby No. 1 ]
#<WorkerThread:0x0000000031bde8> executes [ Request from Alice No. 2 ]
#<WorkerThread:0x0000000031b690> executes [ Request from Chris No. 2 ]
#<WorkerThread:0x0000000031b8c0> executes [ Request from Bobby No. 2 ]
#<WorkerThread:0x0000000031bde8> executes [ Request from Chris No. 3 ]
#<WorkerThread:0x0000000031bb18> executes [ Request from Alice No. 3 ]
#<WorkerThread:0x0000000031b690> executes [ Request from Bobby No. 3 ]
#<WorkerThread:0x0000000031bb18> executes [ Request from Alice No. 4 ]
#<WorkerThread:0x00000002bc7760> executes [ Request from Chris No. 4 ]
#<WorkerThread:0x0000000031b8c0> executes [ Request from Bobby No. 4 ]
#<WorkerThread:0x0000000031b690> executes [ Request from Alice No. 5 ]
以下略

=end

