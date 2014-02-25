# coding: utf-8

#
# 『増補改訂版Java言語で学ぶデザインパターン入門マルチスレッド編』 http://www.hyuki.com/dp/dp2.html
# 
# Producer-Consumer - わたしが作り、あなたが使う
#

require 'thread'
require 'monitor'

class Table
  def initialize(count)
    @buffer = Array.new(count)
    @head = 0
    @tail = 0
    @count = 0
    @lock = Monitor.new()
    @cond = @lock.new_cond()
  end
  
  def put(cake)
    @lock.synchronize {
      puts "#{Thread.current} puts #{cake}"
      while @count >= @buffer.length
        @cond.wait()
      end
      
      @buffer[@tail] = cake
      @tail = (@tail + 1) % @buffer.length
      @count += 1
      @cond.broadcast()
    }
  end
  
  def take()
    @lock.synchronize {
      while @count <= 0
        @cond.wait()
      end
      
      cake = @buffer[@head]
      @head = (@head + 1) % @buffer.length
      @count -= 1
      @cond.broadcast()
      puts "#{Thread.current} takes #{cake}"
      return cake
    }
  end
end


class EaterThread < Thread
  def initialize(name, table, seed)
    @table = table
    @random = Random.new(seed)
    
    block = Proc.new {
      begin
        cake = table.take()
        sleep(@random.rand(5))
      rescue => ex
        puts ex
      end
    }
    super(&block)
  end
end


class MakerThread < Thread
  def initialize(name, table, seed)
    @random = Random.new(seed)
    @table = table
    @lock = Monitor.new
    @@id = 0  # ケーキの通し番号(コックさん全員共通)
    
    block = Proc.new {
      begin
        sleep(@random.rand(5))
        cake = "[ Cake No. #{nextid()} by #{Thread.current} ]"
        table.put(cake)
      rescue => ex
        puts ex
      end
    }
    
    super(&block)
  end

  def nextid()
    @lock.synchronize {
      @@id += 1
      return @@id
    }
  end
end

def main(argv)
  th ||= []
  table = Table.new(3)
  th << MakerThread.new("MakerThread-1", table, 31415)
  th << MakerThread.new("MakerThread-2", table, 92653)
  th << MakerThread.new("MakerThread-3", table, 58979)
  th << EaterThread.new("EaterThread-1", table, 32384)
  th << EaterThread.new("EaterThread-2", table, 62643)
  th << EaterThread.new("EaterThread-3", table, 38327)
  th.each {|t| t.join() }
end

main(ARGV)

=begin
ruby Producer-Consumer.rb
#<MakerThread:0x0000000046bd38> puts [ Cake No. 1 by #<MakerThread:0x0000000046bd38> ]
#<EaterThread:0x0000000046b630> takes [ Cake No. 1 by #<MakerThread:0x0000000046bd38> ]
#<MakerThread:0x0000000046b978> puts [ Cake No. 2 by #<MakerThread:0x0000000046b978> ]
#<EaterThread:0x0000000046b248> takes [ Cake No. 2 by #<MakerThread:0x0000000046b978> ]
#<MakerThread:0x00000002c4c758> puts [ Cake No. 3 by #<MakerThread:0x00000002c4c758> ]
#<EaterThread:0x0000000046b4a0> takes [ Cake No. 3 by #<MakerThread:0x00000002c4c758> ]
=end

