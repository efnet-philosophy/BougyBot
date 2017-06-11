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

    def timezone
      @timezone ||= Timezone.lookup(latitude, longitude)
    end

    def time(t = Time.now)
      timezone.time t
    end
	end
end
