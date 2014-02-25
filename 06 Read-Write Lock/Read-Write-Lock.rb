# coding: utf-8

#
# 『増補改訂版Java言語で学ぶデザインパターン入門マルチスレッド編』 http://www.hyuki.com/dp/dp2.html
# 
# Read-Write Lock - みんなで読むのはいいけれど、読んでる間は書いちゃだめ
#

require 'thread'
require 'monitor'

class ReadWriteLock
  def initialize()
    @lock = Monitor.new()
    @cond = @lock.new_cond()
    @readingReaders = 0  # (A) 実際に読んでいる最中のスレッドの数
    @waitingWriters = 0  # (B) 書くのを待っているスレッドの数
    @writingWriters = 0  # (C) 実際に書いている最中のスレッドの数
    @preferWriter = true  # 書くのを優先するならtrue
  end
  
  def readLock()
    @lock.synchronize {
      while ((@writingWriters > 0) or (@preferWriter and (@waitingWriters > 0)))
        @cond.wait()
      end
      @readingReaders += 1    # (A) 実際に読んでいるスレッドの数を1増やす
    }
  end
  
  def readUnlock()
    @lock.synchronize {
      @readingReaders -= 1    # (A) 実際に読んでいるスレッドの数を1減らす
      @preferWriter = true
      @cond.broadcast()
    }
  end
  def writeLock()
    @lock.synchronize {
      @waitingWriters += 1    # (B) 書くのを待っているスレッドの数を1増やす
      begin
        while ((@readingReaders > 0) or (@writingWriters > 0))
          @cond.wait()
        end
      rescue
      ensure
        @waitingWriters -= 1    # (B) 書くのを待っているスレッドの数を1減らす
      end
      @writingWriters += 1    # (C) 実際に書いているスレッドの数を1増やす
    }
  end
  def writeUnlock()
    @lock.synchronize {
      @writingWriters -= 1    #  (C) 実際に書いているスレッドの数を1減らす
      @preferWriter = false
      @cond.broadcast()
    }
  end
end

class BData
  def initialize(size)
    @lock = ReadWriteLock.new()
    @buffer = Array.new(size)
    @buffer.fill('*')
  end
  
  def read()
    @lock.readLock()
    begin
      return doRead()
    rescue
    ensure
      @lock.readUnlock()
    end
  end

  def write(c)
    @lock.writeLock();
    begin
      doWrite(c)
    rescue
    ensure
      @lock.writeUnlock()
    end
  end

  def doRead()
    newbuf = @buffer.clone()
    slowly()
    return newbuf
  end


  # @buffer を埋めるなら fill() すればいいんだけど
  # 1 文字ごとに slowly() させるのでループしておく
  def doWrite(c)
    0.upto(@buffer.length - 1) {|i|
      @buffer[i] = c
      slowly()
    }
  end
  
  def slowly()
    begin
      sleep(0.5)
    rescue => ex
      puts ex
    end
  end
end




class WriterThread < Thread
  def initialize(data, filler)
    @data = data
    @filler = filler
    @index = 0
    @random = Random.new()
    
    block = Proc.new {
      begin
        while true
          c = nextchar()
          @data.write(c)
          sleep(@random.rand(3))
        end
      rescue => ex
        puts ex
      end
    }
    super(&block)
  end
  
  def nextchar()
    c = @filler[@index]
    @index += 1
    if @index >= @filler.length
      @index = 0
    end
    return c
  end
end


# Thread.current だと分かりづらいので名前をつける
class ReaderThread < Thread
  def initialize(data, n)
    @data = data
    @name = "reader #{n}"
    
    block = Proc.new {
      begin
        while true
          readbuf = @data.read
          puts "#{@name} reads #{readbuf}"
        end
      rescue => ex
        puts ex
      end
    }
    super(&block)
  end
end


def main(argv)
  th ||= []
  data = BData.new(10)
  th << ReaderThread.new(data, 0)
  th << ReaderThread.new(data, 1)
  th << ReaderThread.new(data, 2)
  th << ReaderThread.new(data, 3)
  th << ReaderThread.new(data, 4)
  th << ReaderThread.new(data, 5)
  th << WriterThread.new(data, "ABCDEFGHIJKLMNOPQTSTUVWXYZ")
  th << WriterThread.new(data, "abcdefghijklmnopqrstuvwxyz")
  th.each {|t| t.join() }
end

main(ARGV)

=begin
スレッドごとの print は同期できないか

ruby Read-Write-Lock.rb
reader 2 reads ["*", "*", "*", "*", "*", "*", "*", "*", "*", "*"]
reader 5 reads ["*", "*", "*", "*", "*", "*", "*", "*", "*", "*"]reader 1 reads ["*", "*", "*", "*", "*", "*", "*", "*", "*", "*"]

reader 4 reads ["*", "*", "*", "*", "*", "*", "*", "*", "*", "*"]
reader 3 reads ["*", "*", "*", "*", "*", "*", "*", "*", "*", "*"]
reader 0 reads ["*", "*", "*", "*", "*", "*", "*", "*", "*", "*"]
reader 5 reads ["A", "A", "A", "A", "A", "A", "A", "A", "A", "A"]
reader 3 reads ["A", "A", "A", "A", "A", "A", "A", "A", "A", "A"]reader 1 reads ["A", "A", "A", "A", "A", "A", "A", "A", "A", "A"]

reader 4 reads ["A", "A", "A", "A", "A", "A", "A", "A", "A", "A"]
reader 0 reads ["A", "A", "A", "A", "A", "A", "A", "A", "A", "A"]
reader 2 reads ["A", "A", "A", "A", "A", "A", "A", "A", "A", "A"]
reader 5 reads ["a", "a", "a", "a", "a", "a", "a", "a", "a", "a"]
reader 2 reads ["a", "a", "a", "a", "a", "a", "a", "a", "a", "a"]
reader 3 reads ["a", "a", "a", "a", "a", "a", "a", "a", "a", "a"]
reader 0 reads ["a", "a", "a", "a", "a", "a", "a", "a", "a", "a"]
reader 4 reads ["a", "a", "a", "a", "a", "a", "a", "a", "a", "a"]
reader 1 reads ["a", "a", "a", "a", "a", "a", "a", "a", "a", "a"]
reader 2 reads ["B", "B", "B", "B", "B", "B", "B", "B", "B", "B"]
reader 5 reads ["B", "B", "B", "B", "B", "B", "B", "B", "B", "B"]
reader 1 reads ["B", "B", "B", "B", "B", "B", "B", "B", "B", "B"]
reader 4 reads ["B", "B", "B", "B", "B", "B", "B", "B", "B", "B"]reader 3 reads ["B", "B", "B", "B", "B", "B", "B", "B", "B", "B"]

reader 0 reads ["B", "B", "B", "B", "B", "B", "B", "B", "B", "B"]
reader 0 reads ["b", "b", "b", "b", "b", "b", "b", "b", "b", "b"]
reader 2 reads ["b", "b", "b", "b", "b", "b", "b", "b", "b", "b"]
reader 1 reads ["b", "b", "b", "b", "b", "b", "b", "b", "b", "b"]reader 5 reads ["b", "b", "b", "b", "b", "b", "b", "b", "b", "b"]

reader 4 reads ["b", "b", "b", "b", "b", "b", "b", "b", "b", "b"]
reader 3 reads ["b", "b", "b", "b", "b", "b", "b", "b", "b", "b"]
reader 2 reads ["C", "C", "C", "C", "C", "C", "C", "C", "C", "C"]
reader 5 reads ["C", "C", "C", "C", "C", "C", "C", "C", "C", "C"]
reader 1 reads ["C", "C", "C", "C", "C", "C", "C", "C", "C", "C"]reader 3 reads ["C", "C", "C", "C", "C", "C", "C", "C", "C", "C"]

reader 4 reads ["C", "C", "C", "C", "C", "C", "C", "C", "C", "C"]
reader 0 reads ["C", "C", "C", "C", "C", "C", "C", "C", "C", "C"]
reader 0 reads ["c", "c", "c", "c", "c", "c", "c", "c", "c", "c"]
reader 4 reads ["c", "c", "c", "c", "c", "c", "c", "c", "c", "c"]
reader 1 reads ["c", "c", "c", "c", "c", "c", "c", "c", "c", "c"]reader 5 reads ["c", "c", "c", "c", "c", "c", "c", "c", "c", "c"]

reader 3 reads ["c", "c", "c", "c", "c", "c", "c", "c", "c", "c"]
reader 2 reads ["c", "c", "c", "c", "c", "c", "c", "c", "c", "c"]
reader 4 reads ["D", "D", "D", "D", "D", "D", "D", "D", "D", "D"]
reader 3 reads ["D", "D", "D", "D", "D", "D", "D", "D", "D", "D"]reader 5 reads ["D", "D", "D", "D", "D", "D", "D", "D", "D", "D"]

reader 1 reads ["D", "D", "D", "D", "D", "D", "D", "D", "D", "D"]
reader 2 reads ["D", "D", "D", "D", "D", "D", "D", "D", "D", "D"]
reader 0 reads ["D", "D", "D", "D", "D", "D", "D", "D", "D", "D"]

=end


