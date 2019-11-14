# frozen_string_literal: true

require 'timezone'

Timezone::Lookup.config(:geonames) do |c|
  c.username = 'bougyman'
end

module BougyBot
  Zone = Class.new Sequel::Model
  # Notes, async messages
  class Zone
    set_dataset :zones

    def self.lookup(string)
      case string
      when /^[a-zA-Z]{3}$/
        find aircode: string.upcase
      when /^[a-zA-Z]{4}$/
        find weather_code: string.upcase
      else
        find(Sequel.or(name: /#{string}/i, city: /#{string}/i, country: /#{string}/i))
      end
    end

    def self.lookup_city(city, country = nil)
      return find(city: /#{city}/i) if country.nil?

      country.upcase!
      raise "#{country} is not a valid country code" unless find(country: country)

      find(city: /#{city}/i, country: country)
    end

    def self.lookup_latlon(lat, lon)
      place = nil
      %i[admin1_us admin1 countries].detect do |tbl|
        place = DB[tbl].with_sql("select * from #{tbl} where geom && ST_GeomFromText('POINT(#{lon} #{lat})')").first
      end
      return OpenStruct.new(name: 'Nowhere', country: 'Nowhereland') unless place

      OpenStruct.new name: friendly_name(place), country: friendly_country(place)
    end

    def self.friendly_name(place)
      place[:name] || 'Nowhere'
    end

    def self.friendly_country(place)
      country, iso = place.values_at :country, :'iso3166-1-'
      return iso if %w[USA RU].include? iso

      country
    end

    def timezone
      @timezone ||= Timezone.lookup(latitude, longitude)
    end

    def time(now = Time.now)
      timezone.time_with_offset now
    end
  end
end
