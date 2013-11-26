# FiasParser

This gem grabs FIAS database from official site (http://fias.nalog.ru/Public/DownloadPage.aspx) and parses data to usable format. 

## Installation

1. Install system dependecies:

    $ sudo apt-get install unar wget

2. Add this line to your application's Gemfile:

```ruby
  gem 'fias_parser'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fias_parser

## Usage

Example rake-task (Mongoid):

```ruby
  # app/models/street.rb
  class Street
    include Mongoid::Document

    field :name
    field :prefix
    field :guid
    field :okato
  end

  # lib/tasks/fias.rake
  namespace :fias do
    desc "Stores streets to database"

    task install: :environment do
      parser = FiasParser::Parser.new( base_dir: Rails.root.join( 'tmp' ) )

      parser.get_latest

      parser.process( 'as_addrobj', batch_size: 100 ) do |batch|
        batch.each do |item|
          # only active items
          next if item[:ACTSTATUS].to_i != 1
          # streets
          next if item[:AOLEVEL].to_i != 7
          # just Moscow
          next unless /^45/ =~ item[:OKATO]

          Street.create!(
            name: item[:OFFNAME],
            prefix: item[:SHORTNAME],
            okato: item[:OKATO],
            guid: item[:AOGUID]
          )
        end
      end
    end
  end
```

Available xmls:
  AS_ACTSTAT
  AS_ADDROBJ
  AS_CENTERST
  AS_CURENTST
  AS_ESTSTAT
  AS_HOUSE
  AS_HSTSTAT
  AS_INTVSTAT
  AS_LANDMARK
  AS_NDOCTYPE
  AS_NORMDOC
  AS_OPERSTAT
  AS_SOCRBASE
  AS_STRSTAT

XSD schemas look on official site (http://fias.nalog.ru/Public/DownloadPage.aspx)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
