# coding: utf-8

#
# 『増補改訂版Java言語で学ぶデザインパターン入門マルチスレッド編』 http://www.hyuki.com/dp/dp2.html
# 
# Immutable - 壊したくとも、壊せない
#

require 'thread'
require 'monitor'

class Person
  def initialize(name, address)
    @name = name
    @address = address
  end
  
  def getName()
    return @name
  end
  
  def getAddress()
    return @address
  end
  
  def to_s()
    return "[ Person: name = #{@name} address = #{@address} ]"
  end
end

class PrintPersonThread < Thread
  def initialize(person, name)
    @person = person
    @name = name
    
    block = Proc.new() {
      while true
        puts "Thread-#{@name} prints #{@person}"
      end
    }
    super(&block)
  end
end

def main(argv)
  alice = Person.new("Alice", "Alaska");
  th ||= []
  th << PrintPersonThread.new(alice, 0)
  th << PrintPersonThread.new(alice, 1)
  th << PrintPersonThread.new(alice, 2)
  th.each {|t| t.join() }
end

main(ARGV)

=begin

% ruby Immutable.rb
Thread-0 prints [ Person: name = Alice address = Alaska ]
Thread-0 prints [ Person: name = Alice address = Alaska ]
Thread-0 prints [ Person: name = Alice address = Alaska ]
Thread-0 prints [ Person: name = Alice address = Alaska ]
Thread-1 prints [ Person: name = Alice address = Alaska ]
Thread-1 prints [ Person: name = Alice address = Alaska ]
Thread-1 prints [ Person: name = Alice address = Alaska ]
Thread-1 prints [ Person: name = Alice address = Alaska ]
Thread-1 prints [ Person: name = Alice address = Alaska ]
Thread-1 prints [ Person: name = Alice address = Alaska ]
Thread-1 prints [ Person: name = Alice address = Alaska ]
Thread-1 prints [ Person: name = Alice address = Alaska ]
Thread-1 prints [ Person: name = Alice address = Alaska ]
Thread-2 prints [ Person: name = Alice address = Alaska ]
Thread-2 prints [ Person: name = Alice address = Alaska ]
Thread-2 prints [ Person: name = Alice address = Alaska ]
Thread-2 prints [ Person: name = Alice address = Alaska ]
Thread-2 prints [ Person: name = Alice address = Alaska ]
Thread-2 prints [ Person: name = Alice address = Alaska ]
Thread-2 prints [ Person: name = Alice address = Alaska ]
以下略
=end
