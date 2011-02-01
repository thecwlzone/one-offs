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
When generating dates, create random dates for this year and n previous years. Default value is two years back.

--data_map_file file<br />
This file can be used to create data fields. Default fields are (in order) first name, last name, email and phone. See the next section for details.



## Data Map File
You can specify a header and a field to be generated as a key / value pair (but not really a hash).

###Currently supported fields and their data type are:

* name_first - Faker::Name.first_name
* name_last - Faker::Name.last_name
* email - Faker::Internet.email
* phone - Faker::PhoneNumber.phone_number, filtered to be of the form xxx-xxx-xxxx
* transaction_amount - random floating point number between 1.00 and 999.99 - no currency prefix
* transaction_date - Random date from specified number of years back (default = 2) to present in the form of mm/dd/yyyy
* transaction_time - Random time in 24 hour notation in the form of hh:mm:ss
* address_line1 - Faker::Address.street_address
* address_city - Faker::Address.city
* address_state - Faker::Address.us_state_abbr
* address_postal_code - Faker::Address.zip_code - truncated to the US 5 digit format
* loyalty_program_id - a 3 digit integer to be used as a possible customer id, loyalty id, promotion id, etc.

### File format:

Header, field

where field is one of the fields defined in the previous section.

Example:

First Name, name_first<br />
Last Name, name_last<br />
e-Mail, email<br />
Phone, phone<br />

Comment lines are ignored and are denoted by use of the pound sign (#) at the beginning of the line.

## Sample Output

gen_cust_data.rb --records 5 --out_dir ~/tmp --out_file sample_output.csv<br />
cat ~/tmp/sample_output.csv

First Name,Last Name,Email,Phone<br />
Elbert,Schaefer,anika_adams@walter.info,193-624-2792<br />
Cecile,Dibbert,pablo_pfannerstill@koepp.com,373-724-0369<br />
Rudolph,Sporer,janelle@purdy.com,952-843-5185<br />
Lorenz,Leffler,maybelle@frami.name,437-293-2819<br />
Ramona,Reichel,claudie@purdyconroy.info,195-958-1060<br />




