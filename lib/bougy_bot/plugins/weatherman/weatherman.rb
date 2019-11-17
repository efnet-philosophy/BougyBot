# frozen_string_literal: true

require 'cinch'
require 'cinch/cooldown'
require 'time-lord'

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
        @append = if config.key?(:append_forecast)
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
                 Zone.lookup_city place, code.upcase
               else
                 Zone.lookup_city place
               end
        return m.reply "Nothing found for #{query}" unless zone

        m.reply BougyBot::Weather.display_for_zone zone, newlines: false
      rescue StandardError => e
        msg = "[Error!] #{e} fetching weather for query: '#{query}'."
        msg << " Zone which errored: #{zone.full_name}. Complain to bougyman" if zone
        m.reply msg
        return if m.user.nick != 'bougyman'

        m.user.send e.backtrace
      end

      def zweather(m, query) # rubocop:disable Naming/UncommunicativeMethodParamName
        if (zip = query.match(/\b\d\d\d+(?:\s*,\s*\w\w)?\b|\b\w\w\w \w\w\b/))
          z = zip[0].match?(/\b\w\w\w \w\w\w\b/) ? "#{zip[0].split.first},ca" : zip[0]
          m.reply BougyBot::Weather.display_for_zip z, newlines: false
        else
          m.reply BougyBot::Weather.display_for_zip query, newlines: false
        end
      rescue StandardError => e
        m.reply "[Error!] #{e} fetching weather by zip code: #{query}"
        return if m.user.nick != 'bougyman'

        m.user.send e.backtrace
      end

      def forecast(m, query) # rubocop:disable Naming/UncommunicativeMethodParamName
        m.reply "Sorry, No forecasting available yet for #{query} (WIP)"
      end
    end
  end
end
