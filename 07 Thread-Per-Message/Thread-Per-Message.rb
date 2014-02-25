# coding: utf-8

#
# 『増補改訂版Java言語で学ぶデザインパターン入門マルチスレッド編』 http://www.hyuki.com/dp/dp2.html
# 
# Thread-Per-Message - この仕事、やっといてね
#

require 'thread'
require 'monitor'

class Host
  def initialize()
    @helper = Helper.new()
  end
  
  def request(count, c)
    puts "        request(#{count}, #{c}) BEGIN"
    t = Thread.new() {
      @helper.handle(count, c)
    }
    puts "        request(#{count}, #{c}) END"
    return t
  end
  
end

class Helper
  def handle(count, c)
    puts "        handle(#{count}, #{c}) BEGIN"
    0.upto(count) {|i|
      slowly()
      printf c
    }
    puts ""
    puts "        handle(#{count}, #{c}) END"
  end

  def slowly()
    begin
      sleep(2)
    rescue => ex
      puts ex
    end
  end
end


def main(argv)
  th ||= []
  puts "main BEGIN"
  host = Host.new();
  th << host.request(10, 'A')
  th << host.request(20, 'B')
  th << host.request(30, 'C')
  th.each {|t| t.join()}
  puts "main END"
end

main(ARGV)

=begin
>ruby Thread-Per-Message.rb
main BEGIN
        request(10, A) BEGIN
        request(10, A) END
        request(20, B) BEGIN
        request(20, B) END
        request(30, C) BEGIN
        request(30, C) END
        handle(10, A) BEGIN
        handle(20, B) BEGIN
        handle(30, C) BEGIN
ACBCABCABCABCBAACBBCACABCBACABCBA
        handle(10, A) END
BCCBBCCBCBCBBCBCBCB
        handle(20, B) END
CCCCCCCCCCC
        handle(30, C) END
main END
=end


