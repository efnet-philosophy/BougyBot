# -*- coding: utf-8 -*-
module BougyBot
  module Plugins
    class Weatherman
      # Class to manage information for current conditions
      class Weather
        attr_reader :location, :weather, :station

        def initialize(location)
          @data = WeatherUnderground::Base.new.CurrentObservations(location)
          @locations  = @data.display_location
          @location   = @data.display_location.first.full
          @temp       = @data.temperature_string
          @station    = @data.station_id
          @visibility = "#{@data.visibility_mi}m (#{@data.visibility_km}km)"
          @wind       = @data.wind_string
          @windchill  = @data.windchill_string
          @humidity   = @data.relative_humidity
          @pressure   = @data.pressure_string
          @dewpoint   = @data.dewpoint_string
          @weather    = @data.weather
          @weather    = nil if @weather.empty?
          @updated    = @data.observation_time
        end

        def to_s
          s = "In #{@location} it is #{@temp} "
          s << "(feels like #{@windchill}) " if @windchill != 'NA'
          s << "and #{@weather}. "
          s << "Wind #{@wind}, visibility #{@visibility}, humidity #{@humidity}, dewpoint #{@dewpoint}, "
          s << "pressure #{@pressure} (#{@updated} from #{@station})."
        end
      end
    end
  end
end
