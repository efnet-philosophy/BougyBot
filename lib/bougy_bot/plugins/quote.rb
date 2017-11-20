require 'cinch'
require_relative '../../bougy_bot'
require 'cinch/cooldown'
BougyBot::M 'quote'
BougyBot::M 'channel'
BougyBot::M 'log'

# Bot Namespace
module BougyBot
  # Plugin Namespace
  module Plugins
    # Quote Function
    class QuoteR
      @all   = []

      def self.all
        @all
      end
      # rubocop:enable Style/TrivialAccessors

      include ::Cinch::Plugin
      enforce_cooldown
      match(/q(?: ?(.*))?$/, method: :quote)
      match(/last\s+(\d+)\s+(.*)$/, method: :last)
      match(/last\s+(\d+)$/, method: :last)
      match(/last\s+([^\d].*)$/, method: :lastq)
      match(/last$/, method: :last)
      match(/logsearch\s+(\d+)\s+(.*)$/, method: :searchc)
      match(/logsearch\s+([^\d].*)$/, method: :search)
      match(/working\s+(.*)$/, method: :working)
      match(/worklog\s*(.*)$/, method: :worklog)
      match(/(?:countq)$/, method: :count)

      def initialize(*args)
        super
      end

      def worklog(m, q = nil)
        user = m.user
        chan = m.channel if m.channel
      end

      def working(m, work)
        user = m.user
        chan = m.channel if m.channel
        Worklog.heard(m.user, m.message, chan)
      end

      def count(m)
        m.reply "Currently #{Quote.summary}"
      end

      def lastq(m, query)
        last(m, 20, query)
      end

      def last(m, count = 20, query = nil)
        if count.to_i > 100
          m.reply "You want fucking #{count} pms? Don't abuse the search bot, #{m.user.nick}. See the rulez, that's a dick(cunt)-move."
          return
        end
        user = m.user
        chan = m.channel
        db_channel = Channel.find(name: chan.name)
        unless db_channel
          m.reply "#{user.nick}: Could not find channel entry for #{chan.name} in db! Sorry."
          return
        end
        ds = ChanLog.where(channel_id: db_channel.id)
        ds = ds.where(Sequel.~(message: /!last/))
        if query
          begin
            regex = Regexp.new(query, Regexp::IGNORECASE)
          rescue => e
            m.reply "#{user.nick}: Invalid Regular Expression!"
            user.msg("Error: #{e}")
            return
          end
          ds = ds.where(message: /#{query}/i)
        end
        ds = ds.order(Sequel.desc(:at)).limit(count)
        found_count = ds.count
        qstring = query || 'ALL'
        if found_count == 0
          m.reply "#{user.nick}: Sorry, no messages match your query: #{qstring}"
        else
          m.reply "#{user.nick}: Showing #{found_count} messages in pm. Query: #{qstring}"
          ds.all.reverse.each do |chan_log|
            user.msg chan_log.display
          end
        end
      rescue => e
        m.reply "Wo, something went wrong with your query, #{user.nick}. Sending backtrace in pm"
        user.msg e
        e.backtrace.each do |err|
          user.msg err
        end
      end

      def searchc(m, count, query)
        search(m, query, count)
      end

      def search(m, query, count = 20)
        if count.to_i > 100
          m.reply "You want fucking #{count} pms? Don't abuse the search bot, #{m.user.nick}. See the rulez, that's a dick(cunt)-move."
          return
        end
        user = m.user
        chan = m.channel
        ds = ChanLog.where(message: /#{query}/i)
        ds = ds.where(Sequel.~(message: /!logsearch/))
        ds = ds.order(Sequel.desc(:at)).limit(count)
        found_count = ds.count
        if found_count == 0
          m.reply "#{user.nick}: Sorry, no messages match your query: #{query}"
        else
          m.reply "#{user.nick}: Showing #{found_count} messages in pm. Query: #{query}"
          ds.all.reverse.each do |chan_log|
            user.msg chan_log.display
          end
        end
      rescue => e
        m.reply "Wo, something went wrong with your query, #{user.nick}. Sending backtrace in pm"
        user.msg e
        e.backtrace.each do |err|
          user.msg err
        end
      end

      def quote(m, query)
        return m.reply Quote.sample.display if query.nil? || query == ''
        m.reply Quote.best(query).display
      rescue => e
        log 'Died on quote!', :warn
        log e.to_s, :warn
        m.reply "#{m.user.nick}: No dice"
      end
    end
  end
end
