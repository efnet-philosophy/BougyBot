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

      def self.unthrottle
        @abuse = {}
        @all = []
      end

      # rubocop:disable Style/TrivialAccessors
      def self.abuse
        @abuse
      end

      def self.all
        @all
      end
      # rubocop:enable Style/TrivialAccessors

      include ::Cinch::Plugin
      match(/q(?: ?(.*))?$/, method: :quote)
      match(/(?:countq)$/, method: :count)

      def initialize(*args)
        super
      end

      def abuse?
        now = Time.now
        all = self.class.all
        syncronize(:abuse) do
          all << now
          all = all.sort.reverse[0..180]
        end
        abusive? all, 3
      rescue => e
        log.warn "Error in abuse?: #{e}"
        true
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def abuser?(nick)
        now = Time.now
        ab = self.class.abuse
        all = self.class.all
        synchronize(:abuser) do
          ab[nick] ||= []
          ab[nick] << now
          all << now
          ab[nick] = ab[nick].sort.reverse[0..25]
        end
        abusive? ab[nick]
      rescue => e
        log.warn "Error in abuse?: #{e}"
        log.warn "Error in abuse?: #{e.backtrace.join("\n")}}"
        true
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def abuse_level?(times, comparitor, seconds, now)
        times.select { |t| now - t < seconds }.size > comparitor
      end

      def abuse1?(times, _, now = Time.now)
        return '> 1 in 30 seconds' if abuse_level?(times, 1, 30, now)
        nil
      end

      def abuse2?(times, level, now = Time.now)
        l = 3 * level
        return "> #{l} in 3 minutes" if abuse_level?(times, l, 180, now)
        nil
      end

      def abuse3?(times, level, now = Time.now)
        l = 24 * level
        return "> #{l} in 24 hours" if abuse_level?(times, l, 86_400, now)
        nil
      end

      # rubocop:disable Metrics/AbcSize
      def abusive?(times, level = 1)
        now = Time.now
        args = [times, level, now]
        abuse1?(*args) || abuse2?(*args) || abuse3?(*args)
      rescue => e
        log "Wtf abusive? #{times}: #{level}", :warn
        log e.to_s, :warn
        true
      end

      def count(m)
        return if abuser?(m.user.host)
        m.reply "Currently #{Quote.summary}"
      end

      def quote(m, query)
        abuse_message = abuser?(m.user.host)
        return m.user.send("THROTTLED! (#{abuse_message})") if abuse_message
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
