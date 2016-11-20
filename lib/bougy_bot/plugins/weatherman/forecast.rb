# -*- coding: utf-8 -*-
module BougyBot
  module Plugins
    class Weatherman
      # Class to manage information on future conditions
      class Forecast
        def initialize(location)
          data = WeatherUnderground::Base.new.TextForecast(location)
          next_period = data.days[1]
          fail ArgumentError if next_period.nil?

          @location       = Weather.new(location).location
          @results = [1, 2, 3].map do |i|
            if deez = data.days[i]
              {name: deez.title, text: deez.text}
            end
          end.compact
        end

        def to_s
          s = @results.map do |item|
            "#{item[:name]} #{item[:text]}"
          end
          "In #{@location} #{s.join}"
        end

        def append
          to_s.gsub(" in #{@location}", '')
        end
      end
    end
  end
end
