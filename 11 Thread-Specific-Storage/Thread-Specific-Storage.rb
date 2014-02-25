# coding: utf-8

#
# 『増補改訂版Java言語で学ぶデザインパターン入門マルチスレッド編』 http://www.hyuki.com/dp/dp2.html
# 
# Thread-Specific Storage - スレッドごとのコインロッカー
#

require 'thread'
require 'monitor'

class TSLog
  def initialize(filename)
    @writer = nil
    
    begin
      @writer = File.open(filename, "w")
    rescue => ex
      puts ex
    end
  end
  
  def println(s)
    @writer.puts(s)
  end
  
  def close()
    @writer.puts("==== End of log ====")
    @writer.close()
  end
end

class Log
  # ログを書く
  def self.println(name, s)
    getTSLog(name).println(s)
  end

  # ログを閉じる
  def self.close(name)
    getTSLog(name).close()
  end

  # スレッド固有のログを得る
  def self.getTSLog(name)
    tsLog = Thread.current.thread_variable_get(name)
    
    # そのスレッドからの呼び出しがはじめてなら、新規作成して登録する
    if tsLog == nil
      tsLog = TSLog.new("#{name}-log.txt")
      Thread.current.thread_variable_set(name, tsLog)
    end
    return tsLog
  end
end

class ClientThread < Thread
  def initialize(name)
    @name = name
    
    block = Proc.new {
      puts "#{@name} BEGIN"
      0.upto(10) {|i|
          Log.println(@name, "i = #{i}")
          begin
            sleep(1)
          rescue => ex
            puts ex
          end
      }
      Log.close(@name)
      puts "#{@name} END"
    }
    super(&block)
  end
end

def main(argv)
  th ||= []
  th << ClientThread.new("Alice")
  th << ClientThread.new("Bobby")
  th << ClientThread.new("Chris")
  th.each {|t| t.join() }
end

main(ARGV)

=begin
>ruby Thread-Specific-Storage.rb
Alice BEGIN
Bobby BEGIN
Chris BEGIN
Bobby END
Chris END
Alice END
=end

