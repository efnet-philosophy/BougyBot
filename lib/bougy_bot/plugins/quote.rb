require 'cinch'
require_relative '../../bougy_bot'
BougyBot::M 'quote'

# Bot Namespace
module BougyBot
  # Plugin Namespace
  module Plugins
    # Quote Function
    class QuoteR
      @abuse = {}
      @all   = []

      # rubocop:disable Style/TrivialAccessors
      def self.abuse
        @abuse
      end

      def self.all
        @all
      end
      # rubocop:enable Style/TrivialAccessors

      include ::Cinch::Plugin
      match(/(?:q|qu|quo|quot|quote)(?: (.*))?$/)

      def initialize(*args)
        super
      end

      def abuse?
        now = Time.now
        all = self.class.all
        syncronize(:abuse) do
          all << now
          all = ab[nick].sort.reverse[0..180]
        end
        abusive? all, 3
      end

      def abuser?(nick)
        now = Time.now
        ab = self.class.abuse
        synchronize(:abuser) do
          ab[nick] ||= []
          ab[nick] << now
          ab[nick] = ab[nick].sort.reverse[0..25]
        end
        abusive? ab[nick]
      end
      # rubocop:disable Metrics/AbcSize
      def abusive?(times, level = 1)
        now = Time.now
        return true if times.select { |t| now - t < 30 * level }.size > 1
        return true if times.select { |t| now - t < 180 * level }.size > 5
        times.select { |t| now - t < 86_400 * level }.size > 24
      end

      def execute(m, query)
        return if abuser?(m.user.nick)
        return m.reply Quote.sample.display if query.nil? || query == ''
        m.reply Quote.best(query).display
      rescue => e
        log 'Died on quote!', :warn
        log e.to_s, :warn
        m.reply "#{m.user.nick}: No dice"
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
