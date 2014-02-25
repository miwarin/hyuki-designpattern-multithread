# coding: utf-8

#
# 『増補改訂版Java言語で学ぶデザインパターン入門マルチスレッド編』 http://www.hyuki.com/dp/dp2.html
# 
# Two-Phase Termination - 後片付けしてから、おやすみなさい
#

require 'thread'
require 'monitor'


class CountupThread < Thread
  def initialize()
    # カウンタの値
    @counter = 0

    # 終了要求が出されたらtrue
    @shutdownRequested = false
    
    # 動作
    block = Proc.new {
      begin
        while !isShutdownRequested() == false
          doWork()
        end
      rescue => ex
        puts ex
      ensure
        doShutdown()
      end
    }
    super(&block)
  end
  
  # 終了要求
  def shutdownRequest()
    @shutdownRequested = true
    wakeup()
  end
  
  # 終了要求が出されたかどうかのテスト
  def isShutdownRequested()
    return @shutdownRequested
  end
  
  # 作業
  def doWork()
    @counter += 1
    puts "doWork: counter = #{@counter}"
    sleep(0.5)
  end

  # 終了処理
  def doShutdown()
    puts "doShutdown: counter = #{@counter}"
  end
  
end


def main(argv)
  puts "main: BEGIN"
  begin
    # スレッドの起動
    t = CountupThread.new()
#    t.join()

    # 少し時間をあける
    sleep(5);

    # スレッドの終了要求
    puts "main: shutdownRequest"
    t.shutdownRequest()

    puts "main: shutdown"

  rescue => ex
    puts ex
  end
  puts "main: END"
end

main(ARGV)


=begin
>ruby Two-Phase-Termination.rb
main: BEGIN
doShutdown: counter = 0
main: shutdownRequest
killed thread
main: END


=end
