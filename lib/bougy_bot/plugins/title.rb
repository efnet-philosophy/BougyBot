require 'cinch'
require 'nokogiri'
require 'open-uri'

# Bot Namespace
module BougyBot
  # Plugin namespace
  module Plugins
    # Title & Url shortening bot
    class Title
      include Cinch::Plugin

      listen_to :channel
      def initialize(*args)
        @abuse = {}
        super
      end

      def abuser?(nick)
        now = Time.now
        synchronize(:abuser) do
          @abuse[nick] ||= []
          @abuse[nick] << now
        end
        @abuse[nick] = @abuse[nick].sort.reverse[0..15]
        abusive? @abuse[nick]
      end

      def abusive?(times)
        now = Time.now
        times.select { |t| now - t < 180 }.size > 10
      end

      def listen(m)
        nick = m.user.nick
        return if nick == bot.nick
        return if nick =~ /^(?:pangaea|GitHub|xbps-builder$|void-packages$)/
        log = do_log m
        return if abuser? nick
        return if Url.abuser? nick
        title_urls m, log.channel_id
      end

      def do_log(m)
        ChanLog.heard m.channel, m.user, m.message
      end

      def title_urls(m, channel_id)
        urls = URI.extract(m.message, %w(http https))
        urls.each do |u|
          m.reply Url.heard(u, m.user.nick, channel_id).display_for(m.user.nick)
        end
      end
    end
  end
end
