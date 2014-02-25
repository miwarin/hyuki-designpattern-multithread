# coding: utf-8

#
# 『増補改訂版Java言語で学ぶデザインパターン入門マルチスレッド編』 http://www.hyuki.com/dp/dp2.html
# 
# Balking - 必要なかったら、やめちゃおう
#

require 'thread'
require 'monitor'

class BData
  def initialize(filename, content)
    @filename = filename
    @content = content
    @changed = true
    @lock = Monitor.new()
  end
  
  def change(newContent)
    @lock.synchronize {
      @content = newContent
      @changed = true
    }
  end
  
  def save()
    @lock.synchronize {
      if @changed == false
        return
      end
      doSave()
      @changed = false
    }
  end
  
  def doSave()
    puts "#{Thread.current} calls doSave, content = #{@content}"
    File.open(@filename, "wb") {|f|
      f.write(@content)
    }
  end
end

class ChangerThread < Thread
  def initialize(name, data)
    @data = data
    @random = Random.new()
    
    block = Proc.new {
      i = 0
      begin
        while true
          @data.change("No. #{i}")
          sleep(1)
          @data.save()
          i += 1
        end
      rescue => ex
        puts ex
      end
    }
    super(&block)
  end
  
end

class SaverThread < Thread
  def initialize(name, data)
    @data = data
    
    block = Proc.new {
      begin
        while true
          @data.save()
          sleep(2)
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
  data = BData.new("data.txt", "(empty)")
  th << ChangerThread.new("ChangerThread", data)
  th << SaverThread.new("SaverThread", data)
  th.each {|t| t.join() }
end

main(ARGV)

=begin
>ruby Balking.rb
#<SaverThread:0x000000002fbdb8> calls doSave, content = No. 0
#<ChangerThread:0x00000002b7e218> calls doSave, content = No. 1
#<SaverThread:0x000000002fbdb8> calls doSave, content = No. 2
#<ChangerThread:0x00000002b7e218> calls doSave, content = No. 3
#<SaverThread:0x000000002fbdb8> calls doSave, content = No. 4
#<ChangerThread:0x00000002b7e218> calls doSave, content = No. 5
#<SaverThread:0x000000002fbdb8> calls doSave, content = No. 6
#<ChangerThread:0x00000002b7e218> calls doSave, content = No. 7
#<SaverThread:0x000000002fbdb8> calls doSave, content = No. 8
#<ChangerThread:0x00000002b7e218> calls doSave, content = No. 9
#<SaverThread:0x000000002fbdb8> calls doSave, content = No. 10
#<ChangerThread:0x00000002b7e218> calls doSave, content = No. 11
#<SaverThread:0x000000002fbdb8> calls doSave, content = No. 12
=end

