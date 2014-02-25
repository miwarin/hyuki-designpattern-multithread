# coding: utf-8

#
# 『増補改訂版Java言語で学ぶデザインパターン入門マルチスレッド編』 http://www.hyuki.com/dp/dp2.html
# 
# Single Threaded Execution - この橋を渡れるのは、たった一人
#

require 'thread'
require 'monitor'

class Gate
  def initialize()
    @counter = 0
    @name = "Nobody"
    @address = "Nowhere"
    @lock = Monitor.new
  end

  def pass(name, address)
    @lock.synchronize {
      @counter += 1
      @name = name
      @address = address
      check()
    }
  end

  def to_s()
    @lock.synchronize {
      return "No. #{@counter}: #{@name} #{@address}"
    }
  end
  
  def check()
    puts to_s()
    if @name[0] != @address[0]
      puts "***** BROKEN ***** " + to_s()
    end
  end
end

class UserThread < Thread
  def initialize(gate, myname, myaddress)
    @gate = gate
    @myname = myname
    @myaddress = myaddress
    
    super() {
      puts @myname + " BEGIN"
      while true
        @gate.pass(@myname, @myaddress)
        sleep(1)
      end
    }
    
  end
end


def main(argv)
  gate = Gate.new
  threads ||= []

  threads << UserThread.new(gate, "Alice", "Alaska")
  threads << UserThread.new(gate, "Bobby", "Brazil")
  threads << UserThread.new(gate, "Chris", "Canada")
  threads.each {|t|
    t.join()
  }
end

main(ARGV)


=begin

% ruby SingleThreadedExecution.rb
Alice BEGIN
No. 1: Alice Alaska
Bobby BEGIN
No. 2: Bobby Brazil
Chris BEGIN
No. 3: Chris Canada
No. 4: Alice Alaska
No. 5: Bobby Brazil
No. 6: Chris Canada
No. 7: Chris Canada
No. 8: Bobby Brazil
No. 9: Alice Alaska
No. 10: Chris Canada
No. 11: Alice Alaska
No. 12: Bobby Brazil
No. 13: Alice Alaska
No. 14: Bobby Brazil
No. 15: Chris Canada
No. 16: Chris Canada
No. 17: Alice Alaska
No. 18: Bobby Brazil
SingleThreadedExecution.rb:67:in `join': Interrupt
        from SingleThreadedExecution.rb:67:in `block in main'
        from SingleThreadedExecution.rb:66:in `each'
        from SingleThreadedExecution.rb:66:in `main'
        from SingleThreadedExecution.rb:72:in `<main>'

=end
