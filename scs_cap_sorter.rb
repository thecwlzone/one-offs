#!/usr/bin/env ruby
#
# = Description
# Sort capacitors by size, per node, from a *.scs file.
#
# Sample output:
#
#  Node name XYZ ; Total capacitance = 100fF
#  C1 XYZ node1 60fF 60%
#  C2 XYZ node2 30fF 30%
#  C3 XYZ node3 10fF 10%
#
# Inputs: A *.scs file
#
# Outputs: A text file with the results
#
# = Syntax:
#          cap_sorter.rb [ --help | -h ] [ --verbose | -v ] [--units f | p | n | u | m]
#                        [--out_file outfile_name] --in_file scs_file
#
# = Syntax Examples:
#          cap_sorter.rb --in_file U6KX_TX_PREDRV_DATA.scs
#          cap_sorter.rb --out_file U6KX_TX_PREDRV_DATA_sorted_caps.txt --in_file U6KX_TX_PREDRV_DATA.scs
#          cap_sorter.rb --units f --out_file U6KX_TX_PREDRV_DATA_sorted_caps.txt --in_file U6KX_TX_PREDRV_DATA.scs
#
# = Usage:
# Sort caps by node and size, specifying <b>f</b>emto/<b>p</b>ico/<b>n</b>ano/<b>u</b> micro/<b>m</b>illi Farads using the --units switch
#
# Default output file name is <em>scs_file</em>_sorted_caps.txt
#
# Default unit value is femtoFarads (fF)
#
# For large *.scs files, use the --verbose option to see what the program is doing
#
# This is Ruby code, (Ruby rocks!), so the program needs to run on a Linux machine
#
# Author: Chris W. Lehman
#
# = How To Run It:
# The program is: scs_cap_sorter.rb
#
# You can copy it to another location, or run it in place using an alias in your .cshrc file:
#
# <b>alias scs_sort_cap '/some_path/scs_cap_sorter.rb'</b>
#
# Then, in a Linux terminal window, type <tt>scs_sort_cap --help</tt> to see the syntax examples
#
# = Program Status:
# <b>Probably obsolete</b>
#
class CapSorter
  require 'getoptlong'

  ####
  def initialize
    @sorted_nets = Array.new
    @input_file = ""
    @output_file = ""
    @units = "femto"
    @verbose = false
    @full_syntax = "scs_cap_sorter.rb [ --help | -h ] [ --verbose | -v ] [--units f | p | n | u | m] [--out_file outfile_name] --in_file scs_file"
    @example_syntax = " scs_cap_sorter.rb --in_file U6KX_TX_PREDRV_DATA.scs\n cap_sorter.rb --out_file U6KX_TX_PREDRV_DATA_sorted_caps.txt --in_file U6KX_TX_PREDRV_DATA.scs\n cap_sorter.rb --units f --out_file U6KX_TX_PREDRV_DATA_sorted_caps.txt --in_file U6KX_TX_PREDRV_DATA.scs"
    @usage = "\nSort caps by node and size, specifying femto/pico/nano/micro/milli Farads:\n#{@full_syntax}\nExample syntax:\n#{@example_syntax}\nDefault output file name is scs_file_name_sorted_caps.txt\nDefault unit value is femtoFarads (fF)\n"

    if ARGV.size < 1 || ARGV.size > 7
      STDERR.puts "scs_cap_sorter.rb: Incorrect number of arguments..."
      STDERR.puts "#{@full_syntax}"
      STDERR.puts "Example syntax:"
      STDERR.puts "#{@example_syntax}"
      exit
    end

    get_options

    @output_file = @input_file.chomp(".") + "_sorted_caps.txt" if @output_file.empty?
    puts "\n scs_cap_sorter Program Start" if @verbose

  end # initialize

  ####
  def get_options
    @opts = GetoptLong.new(
                           [ "--help", "-h", GetoptLong::NO_ARGUMENT ],
                           [ "--debug", GetoptLong::NO_ARGUMENT ],
                           [ "--verbose", "-v", GetoptLong::NO_ARGUMENT ],
                           [ "--units", GetoptLong::REQUIRED_ARGUMENT ],
                           [ "--out_file", GetoptLong::REQUIRED_ARGUMENT ],
                           [ "--in_file", GetoptLong::REQUIRED_ARGUMENT ]
                           )

    @opts.each do |opt, arg|
      case opt
      when "--help",    "-h"
        puts @usage
        exit
      when "--debug"
        $DEBUG = 1
      when "--verbose", "-v"
        @verbose = true
      when "--units"
        case arg
          when "f"
          @units = "femto"
          when "p"
          @units = "pico"
          when "n"
          @units = "nano"
          when "u"
          @units = "micro"
          when "m"
          @units = "milli"
        end
      when "--out_file"
        @output_file = arg
      when "--in_file"
        @input_file = arg
      else
        puts @usage
        exit
      end # case
    end # @opts.each
  end # get_options

  ####
  def generate_net_list
    # Read the input file, capture the net definitions
    # A *.scs NET statement looks like:
    # // |NET XI101/ln_X_563 1.51392e-06PF
    # Generate a hash where key = the net name and value = the total cap value
    #
    puts " Generating list of net names..." if @verbose
    @nets = Hash.new
    IO.foreach(@input_file) do |line|
      next if line !~ /\/\/ \|NET/
      net_name = line.split(" ")[2]
      cap_value = sci_note_convert(line.split(" ")[3], @units, "string")
      @nets[net_name] = cap_value
    end
    @nets.each { |x, y| puts "Net = #{x}, Cap Value = #{y}" } if $DEBUG
    return true    
  end

  ####
  def generate_cap_list
    # Read the input file, capture all the capacitor statements
    # A *.scs capacitor statement looks like:
    # C59246  ( XI204\/ln_X_106\:127805  XI204\/ln_X_1389\:129258 )  capacitor  c=9.52528e-18
    #
    puts " Generating list of capacitors..." if @verbose
    @cap_statement = Array.new
    IO.foreach(@input_file) do |line|
      next if line =~ /^\/\// || line =~ /^$/
      if line =~ /capacitor/
        x = line.split(" ")
        cap_val = sci_note_convert(x[6].sub!("c=", ''), @units, "string")
        x[6] = "c=" + cap_val
        line = x.join(" ")        
        @cap_statement << line
      end
    end
    @cap_statement.each { |x| puts x } if $DEBUG
    return true
  end

  ####
  def sort_by_netname
    puts " Sorting cap list and calculating percentages. (This may take some time...)" if @verbose
    @i = 0
    @nets.each do |net_name, total_cap_value|
      @i = @i + 1
      if @verbose && @i == 500
        puts "  Still sorting..."
        @i = 0
      end
      @sorted_nets << "Net #{net_name} ; Total capacitance = #{total_cap_value}"
      unsorted_caps = Array.new
      sorted_caps = Array.new
      sorted_caps_with_percentage = Array.new
      @cap_statement.each do |z|
        if z.match(net_name)
          unsorted_caps << "#{z}"
        end
      end
      sorted_caps = unsorted_caps.sort { |a, b|
        sci_note_convert(a.split(" ")[6].sub!("c=", ''), @units, "float") <=> sci_note_convert(b.split(" ")[6].sub!("c=", ''), @units, "float")
      }
      sorted_caps = sorted_caps.reverse
      sorted_caps.each do |x|
        cap_val = sci_note_convert(x.split(" ")[6].sub!("c=", ''), @units, "string")
        cap_percent = (cap_val.match(/\d*\.\d+/).to_s.to_f / total_cap_value.match(/\d*\.\d+/).to_s.to_f) * 100.0
        sorted_caps_with_percentage << x + " " + sprintf("%2.1f", cap_percent) + "%"
      end
      sorted_caps_with_percentage.each do |x|
        @sorted_nets << x
      end
      @sorted_nets << ""
    end
    return true
  end

  ####
  def write_results
    puts " Writing results to #{@output_file}..." if @verbose
    of = File.new(@output_file, "w")
    @sorted_nets.each do |line|
      of.puts line
    end
    of.close
    puts " scs_cap_sorter Program Complete\n\n" if @verbose
  end

  ####
  def sci_note_convert(value, range, type)
    # Convert a string representing a capacitance value in scientific notation
    # (with or without a Farad suffix) into an appropriate value range,
    # (e.g. milli, micro, nano, pico, femto) and return either a new string or a float type.
    #
    # value is a string of the form:
    # nn.nnnnne-nn or
    # nn.nnnnn[fF]|[pP]|[mM]]|[uU][fF] or
    # nn.nnnnne-nn[fF]|[pP]|[uU]|[mM]][fF] or
    # nn.nnnnne-nn
    # i.e. value is a string that looks like:
    # 5.3753e-05PF or
    # 0.000606313fF or
    # 3.1314mf or
    # 6.57156e-18
    #
    # Range is the target multiplier: 
    # femto = 1e-15, pico = 1e-12, nano = 1e-9, micro = 1e-6, milli = 1e-3
    #
    # type is "string" or "float", the value to be returned. If "string", then
    # return the form:
    # nn.nnnnnn[F|P|N|M][F]
    #
    range = range.downcase
    type = type.downcase
    unit = ""
    suffix = value.match(/\D+\D*$/).to_s
    if suffix && suffix.length == 2
      unit = suffix.chop.upcase
    end
    if suffix && suffix.length == 1
      unit = suffix.upcase
    end

    case unit
      when "F"
      multiplier = 1.0e-15
      when "P"
      multiplier = 1.0e-12
      when "N"
      multiplier = 1.0e-9
      when "U"
      multiplier = 1.0e-6
      when "M"
      multiplier = 1.0e-3
      else
      multiplier = 1.0e-0
    end
    # nn.nnnnnne-nn or nn.nnnnnn
    raw_number = value.to_f * multiplier

    # At this point, raw_number is of type float with a value of n.nnnnne[-+]nn
    return raw_number if type == "float"

    # The string format wants to be nn.nnnnn[F]|[P]|[U]|[M]][F]
    case range
      when "femto"
      i_range = 15
      s_range = "f"
      when "pico"
      i_range = 12
      s_range = "p"
      when "nano"
      i_range = 9
      s_range = "n"
      when "micro"
      i_range = 6
      s_range = "u"
      when "milli"
      i_range = 3
      s_range = "m"
      else
      i_range = 1
      s_range = ""
    end

    new_raw_number = raw_number * 10**(i_range).to_f
    s_raw_number = new_raw_number.to_s + s_range + "F"
    return s_raw_number
  end

  ####
  def check_file_integrity
    unless File.exist?(@input_file) && File.readable?(@input_file)
      puts "\nERROR: File #{@input_file} does not exist or does not have read permission."
      return false
    end

    unless File.exist?(@output_file) || ! File.writable?(@output_file)
      puts "\nERROR: File #{@output_file} already exists, but you do not have write permission."
      return false
    end

    unless File.exist?(File.dirname(@output_file))
      puts "\nERROR: The directory #{File.dirname(@output_file)} does not exist."
      return false
    end

    return true
  end # check_file_integrity

end # class CapSorter

###########
## Main
#
sorted_caps = CapSorter.new
unless sorted_caps.check_file_integrity then exit 1 end
unless sorted_caps.generate_net_list then exit 1 end
unless sorted_caps.generate_cap_list then exit 1 end
unless sorted_caps.sort_by_netname then exit 1 end
sorted_caps.write_results
