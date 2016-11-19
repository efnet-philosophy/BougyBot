# -*- coding: utf-8 -*-
module BougyBot
  module Plugins
    class Weatherman
      # Class to manage information on future conditions
      class Forecast
        def initialize(location)
          data = WeatherUnderground::Base.new.TextForecast(location)
          tomorrow = data.days[2]
          fail ArgumentError if tomorrow.nil?

          @location       = Weather.new(location).location
          @day_name       = tomorrow.title
          @forecast_day   = tomorrow.text

          tomorrow_night = data.days[3]
          @night_name     = tomorrow_night.title if tomorrow_night
          @forecast_night = tomorrow_night.text if tomorrow_night
        end

        def to_s
          s = "#{@day_name} in #{@location}: #{@forecast_day}, "
          s << "#{@night_name}: #{@forecast_night}" if @night_name
          s
        end

        def append
          to_s.gsub(" in #{@location}", '')
        end
      end
    end
  end
end
