#!/usr/bin/ruby
# client_latency_test.rb
# Use drb to simulate file/data transfer
#

require 'drb'
require 'timeout'

# This is the IP address or URL and port of the server (i.e. the other machine)
# You install this code on the client, and invoke it by running "./client_side_latency_test.rb"

machine = "192.168.1.3"
port    = "50000"

the_Domain = `hostname`.chomp!
#load_Factor = `uptime`.split(" ")[7..9].join(" ")
load_Factor = /load average: \d\.\d\d/.match(`uptime`)

finish_message = "Normal completion\n"

# Create a test file - this can be any string you like
test_string = "Fri Aug 27 07:58:35 2010:Completed job #1092344959 user llx program ncverilog_ictpli /proj/7c0852...\nCONT - waited 0 seconds to start\nCONT - ran for 257 secs wall clock time\nCONT - consumed 1 CPU seconds\nCONT - maxvss was 349540\nCONT - maxrss was 329204\nCONT - ran on a machine with 2016 Mb of RAM and a relative power of 24484\nCONT - ran on host wolf11\n"

test_file = the_Domain + "_test_file"
t = File.open(test_file, "w")

puts "Creating test file..."
10000.times do
  t.write(test_string)
end
t.close
puts "Done creating test file."

DRb.start_service()

begin
  remote_obj = DRbObject.new(nil, "druby://#{machine}:#{port}")

rescue DRb::DRbConnError => err
  $stderr.print "Ooops! Is the server running? \n #{err}\n"
end

begin
  puts "Starting file transfer from #{the_Domain} at #{Time.now}"
timeout (3600) do
    remote_obj.log(IO.readlines(test_file), the_Domain, Time.now.to_i, load_Factor)
end
rescue TimeoutError => err
  $stderr.print "File transfer from #{the_Domain} timed out before completion\n"
  finish_message = "File transfer failed\n"
end

begin
  remote_obj.Finish
rescue DRb::DRbConnError => err
  $stderr.print "#{finish_message}"
end

File.delete(test_file)


