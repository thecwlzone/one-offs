#!/usr/bin/env ruby
# server_latency_test.rb
# Simulates transfers between client and server
#

require 'drb'

# This is the IP address or URL and port of the server
# You install this code on the server, and invoke it by running "./server_side_latency_test.rb"
machine = "192.168.1.3"
port    = "50000"

class TestServer
  def initialize(logfile)
    @logfile = logfile
  end

  def log(str, the_Domain, start_time, load_Factor)
    puts "Server accessed from #{the_Domain}"
    File.open(@logfile, "w") { |f|
      str.each { |i| f.puts "#{i}" }
      finish_time = Time.now.to_i
      eTime = (finish_time - start_time).to_s
      f.puts "Transfer time = #{eTime} seconds"
      f.puts "Machine #{load_Factor} during transfer."
      puts "Transfer time = #{eTime} seconds"
      puts "Machine #{load_Factor} during transfer."
    }
  end

  def Finish
    DRb.stop_service()
  end
end

trap(:INT) { puts "Server shutdown"; exit 0 }

server = TestServer.new("latency_test.log")
DRb.start_service("druby://#{machine}:#{port}", server)
DRb.thread.join
