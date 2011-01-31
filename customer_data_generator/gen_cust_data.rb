#!/usr/bin/env ruby

# Overloading Ruby's Time class here, FYI...
class Time
  def self.random(years_back)
    year = Time.now.year - rand(years_back)
    month = rand(12) + 1
    day = rand(31) + 1
    return "#{month}/#{day}/#{year}"
  end
end

class GenCustData
  require 'getoptlong'
  require 'rubygems'
  require 'faker'

  def initialize
    @records = rand(100)
    @data_map_fields = [
      "name_first",
      "name_last",
      "email",
      "phone"
    ]
    @header = "First Name,Last Name,Email,Phone"
    @years_back = 2
    @data_map_file = nil
    @outFile = nil
    @out_file = "customer_data.csv"
    @out_dir = "/tmp"
    @usage = "\nGenerate random amounts of customer data in CSV format, suitable for importing into some kind of Marketing Engine"
    @full_syntax = "  Syntax: gen_cust_data.rb [ --help | -h ] [ --verbose | -v ] [--out_file outfile] [--out_dir outdir] [--data_map_file data_map_file] [--records n] [--years_back n]"
    @example_syntax = "  Example: gen_cust_data.rb --records 10 --out_dir /tmp --out_file my_customers.csv\n"
    get_options
  end
  
  def get_options
    @opts = GetoptLong.new(
    [ "--help", "-h", GetoptLong::NO_ARGUMENT ],
    [ "--debug", GetoptLong::NO_ARGUMENT ],
    [ "--verbose", "-v", GetoptLong::NO_ARGUMENT ],
    [ "--data_map_file", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--out_file", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--out_dir", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--records", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--years_back", GetoptLong::REQUIRED_ARGUMENT ]
    )

    @opts.each do |opt, arg|
      case opt
      when "--help", "-h"
        puts @usage
        puts @full_syntax
        puts @example_syntax
        exit
      when "--debug"
        $DEBUG = 1
      when "--verbose", "-v"
        @verbose = true
      when "--data_map_file"
        @data_map_file = arg
      when "--out_file"
        @out_file = arg
      when "--out_dir"
        @out_dir = arg
      when "--records"
        @records = arg
      when "--years_back"
        @years_back = arg
      else
        puts @usage
        puts @full_syntax
        puts @example_syntax
        exit
      end # case
    end # @opts.each
  end

  def create_out_file
    @outFile = File.open(@out_dir + '/' + @out_file, "w+")
  end
  
  def process_data_map_file
    return false if @data_map_file.nil?
    exit unless @dataMapFile = File.open(@data_map_file, "r")
    @header = ''
    @data_map_fields = []
    @lines = @dataMapFile.readlines
    @lines.each do |line|
      next if line.match(/^\s*#/)
      fields = line.split(',')
      fields[0].gsub!(/\s*#.*$/, '')
      @header << fields[0] + ','
      fields[1].gsub!(/\s+#.*$/, '').strip!
      @data_map_fields << fields[1]
    end
    @header.chomp!(',')
    create_records
  end
  
  def process_default_fields
    create_records
  end

  def create_records
    @outFile.write("#{@header}\n")

    @records.to_i.times do
      @buffer = ''
      @data_map_fields.each do |field|
        case field
        when "name_first"
          @name_first = Faker::Name.first_name
          @buffer << @name_first + ','
        when "name_last"
          @name_last = Faker::Name.last_name
          @buffer << @name_last + ','
        when "phone"
          @phone = Faker::PhoneNumber.phone_number
          @phone = @phone.match(/\A\S+/)[0]
          @phone.gsub!(/\A1-/, '')
          @phone.gsub!('.', '-')
          @phone.gsub!('(', '')
          @phone.gsub!(')', '-')
          @phone.gsub!(/\A0/, '3')
          @buffer << @phone + ','
        when "transaction_amount"
          @transaction_amount = "%3.2f" % ((rand * 100) + 10.00)
          @buffer << @transaction_amount + ','
        when "transaction_date"
          @random_date = Time.random(@years_back).to_s
          @date_fields = @random_date.split('/')
          @date_fields[0] = "0" + @date_fields[0]  if @date_fields[0].length == 1
          @date_fields[1] = "0" + @date_fields[1]  if @date_fields[1].length == 1
          @transaction_date = @date_fields.join('/')
          @buffer << @transaction_date + ','
        when "loyalty_program_id"
          @loyalty_program_id = rand(1000)
          @buffer = @loyalty_program_id + ','
        when "email"
          @email = Faker::Internet.email
          @buffer << @email + ','
        when "transaction_time"
          @transaction_time = Time.at(rand(Time.now)).to_s.split(' ')[3]
          @buffer << @transaction_time + ','
        when "address_line1"
          @address_line1 = Faker::Address.street_address
          @buffer << @address_line1 + ','
        when "address_city"
          @address_city = Faker::Address.city
          @buffer << @address_city + ','
        when "address_state"
          @address_state = Faker::Address.us_state_abbr
          @buffer = @address_state + ','
        when "address_postal_code"
          @address_postal_code = Faker::Address.zip_code.match(/\d{5}/).to_s
          @buffer << @address_postal_code + ','
        else
          @buffer << "UNKNOWN" + ','
        end
      end
      @buffer.chomp!(',')
      @outFile.write("#{@buffer}\n")
    end
  end

  def cleanup
    @outFile.close
  end
end

###########
## Main
#
cust_data = GenCustData.new
unless cust_data.create_out_file then exit 1 end
cust_data.process_default_fields unless cust_data.process_data_map_file
cust_data.cleanup


