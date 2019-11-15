# frozen_string_literal: true

require 'cinch'
require 'cinch/cooldown'
require 'time-lord'
require 'weather-underground'

module BougyBot
  L 'open_weather'
  module Plugins
    # Cinch Plugin to report weather
    class Weatherman
      include Cinch::Plugin

      enforce_cooldown

      self.help = 'Use .w <zip> to see information on the weather.'

      def initialize(*args)
        super
        @append =
          if config.key?(:append_forecast)
            config[:append_forecast]
          else
            false
          end
      end

      match(/(?:wz|zweather) (.+)/, method: :zweather)
      match(/(?:wq|qweather) (.+)/, method: :qweather)
      # match(/forecast (.+)/,      method: :forecast)

      def qweather(m, query) # rubocop:disable Naming/UncommunicativeMethodParamName
        place, code = query.split(/\s*,\s*/, 2)
        zone = if code && code.size == 2
                 BougyBot::Zone.lookup_city place, code.upcase
               else
                 BougyBot::Zone.lookup_city place
               end
        return m.reply "Nothing found for #{query}" unless zone
        m.reply OpenWeather.display_for_zone(zone)&.tr("\n", ' ')
      rescue StandardError => e
        m.reply "Error #{e} fetching weather for #{query}"
        return if m.user.nick != 'bougyman'

        m.user.send e.backtrace
      end

      def zweather(m, query) # rubocop:disable Naming/UncommunicativeMethodParamName
        if (zip = query.match(/\b\d{5,6}(?:\s*,\s*\w\w)?\b|\w\w\w \w\w\w/))
          z = zip[0].match?(/\w\w\w \w\w\w/) ? "#{zip[0].split.first},ca" : zip[0]
          m.reply OpenWeather.display_for_zip(z)&.tr("\n", ' ')
        else
          m.reply OpenWeather.display_for_zip(query)&.tr("\n", ' ')
        end
      rescue StandardError => e
        m.reply "Error #{e} fetching weather for #{query}"
        return if m.user.nick != 'bougyman'

        m.user.send e.backtrace
      end

      def forecast(m, query) # rubocop:disable Naming/UncommunicativeMethodParamName
        m.reply "Sorry, No forecasting available yet for #{query} (WIP)"
      end

      private

      def get_weather(query)
        weather = Weather.new(query)
        return "No data available for #{query}" unless weather.weather && weather.station

        weather << " #{Forecast.new(query).append}" if @append
        debug "#{@append}  #{config}"
        weather
      rescue ArgumentError
        "Sorry, couldn't find #{query}."
      end

      def get_forecast(query)
        Forecast.new(query).to_s
      rescue ArgumentError
        "Sorry, couldn't find #{query}."
      end
    end
  end
end
