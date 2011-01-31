# Customer Data Generator

This code was the result of the need to generate a large amount of unique customer data for a Marketing Engine database. It's Ruby code with a heavy reliance on the Faker gem to randomly generate various customer data fields, such as names, mailing addresses and emails. The output is a CSV file full of customer data.

## Requirements

* Ruby, any version
* RubyGems
* The Faker gem

## Installation

This is a one-off, so just copy the file or the code to a local file and directory, and add the directory to $PATH (or just put it in $HOME/bin).
## Syntax

gen_cust_data.rb [options]

~/bin/gen_cust_data.rb --help

Generate random amounts of customer data in CSV format, suitable for importing into some kind of Marketing Engine

Syntax: gen_cust_data.rb [ --help | -h ] [ --verbose | -v ] [--out_file outfile] [--out_dir outdir] [--data_map_file data_map_file] [--records n] [--years_back n]

Example: gen_cust_data.rb --records 10 --out_dir /tmp --out_file my_customers.csv

## Switches

Command line switches:

--out_file outfile<br />
Default name is customer_data.csv

--out_dir outdir<br />
Default directory is /tmp

--records n<br />
Default number of records is a random value between 1 and 99

--years_back n<br />
When generating dates, create random dates for this year and n previous years. Default value if two years back.

--data_map_file file<br />
This file can be used to create data fields. Default fields are (in order) first name, last name, email and phone. See the next section for details.



## Data Map File
TBD


