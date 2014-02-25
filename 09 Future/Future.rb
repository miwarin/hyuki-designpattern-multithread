# coding: utf-8

#
# 『増補改訂版Java言語で学ぶデザインパターン入門マルチスレッド編』 http://www.hyuki.com/dp/dp2.html
# 
# Future - 引換券を、お先にどうぞ
#

require 'thread'
require 'monitor'

class BData
  def getContent()
  end
end

class RealData < BData
  def initialize(count, c)
    @content = ""
    puts "        making RealData(#{count}, #{c}) BEGIN"
    buffer = Array.new(count)
    0.upto(count - 1) {|i|
      buffer[i] = c
      begin
        sleep(0.1)
      rescue => ex
        puts ex
      end
    }
    puts "        making RealData(#{count}, #{c}) END"
    @content = buffer.join()
  end
  
  def getContent()
    return @content
  end
end

class FutureData < BData
  def initialize()
    @lock = Monitor.new
    @cond = @lock.new_cond()
    @realdata = nil
    @ready = false
  end

  def setRealData(realdata)
    @lock.synchronize() {
      if @ready
        return  # balk
      end
      @realdata = realdata
      @ready = true
      @cond.broadcast()
    }
  end
  
  def getContent()
    @lock.synchronize() {
      while @ready == false
        begin
          @cond.wait()
        rescue => ex
          puts ex
        end
      end
      return @realdata.getContent()
    }
  end
end


class Host
  def initialize()
  end
  
  def request(count, c)
    puts "    request(#{count}, #{c}) BEGIN"

    # (1) FutureDataのインスタンスを作る
    future = FutureData.new()

    # (2) RealDataを作るための新しいスレッドを起動する
    t = Thread.new() {
      realdata = RealData.new(count, c)
      future.setRealData(realdata)
    }
    
    # join() するとここでブロックするのでやってはいけない
#    t.join()

    puts "    request(#{count}, #{c}) END"

    # (3) FutureDataのインスタンスを戻り値とする
    return future;
  end
end


def main(argv)
  puts "main BEGIN"
  host = Host.new()
  data1 = host.request(10, 'A')
  data2 = host.request(20, 'B')
  data3 = host.request(30, 'C')

  puts "main otherJob BEGIN"
  begin
    sleep(2)
  rescue => ex
    puts ex
  end
  puts "main otherJob END"

  puts "data1 = #{data1.getContent()}"
  puts "data2 = #{data2.getContent()}"
  puts "data3 = #{data3.getContent()}"
  puts "main END"
end

main(ARGV)

=begin
>ruby Future.rb
main BEGIN
    request(10, A) BEGIN
    request(10, A) END
    request(20, B) BEGIN
    request(20, B) END
    request(30, C) BEGIN
    request(30, C) END
main otherJob BEGIN
        making RealData(10, A) BEGIN
        making RealData(20, B) BEGIN
        making RealData(30, C) BEGIN
        making RealData(10, A) END
        making RealData(20, B) END
main otherJob END
data1 = AAAAAAAAAA
data2 = BBBBBBBBBBBBBBBBBBBB
        making RealData(30, C) END
data3 = CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
main END
=end


