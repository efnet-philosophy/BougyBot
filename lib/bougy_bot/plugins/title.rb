require 'cinch'
require 'nokogiri'
require 'open-uri'
require 'cinch/cooldown'

# Bot Namespace
module BougyBot
  # Plugin namespace
  module Plugins
    # Title & Url shortening bot
    class Title
      include Cinch::Plugin
      enforce_cooldown

      listen_to :channel
      def initialize(*args)
        @abuse = {}
        super
      end

      def listen(m)
        nick = m.user.nick
        return if nick == bot.nick
        return if nick =~ /^(?:pangaea|GitHub|xbps-builder$|void-packages$)/
        log = do_log m
        title_urls m, log.channel_id
      end

      def do_log(m)
        ChanLog.heard m.channel, m.user, m.message
      end

      def title_urls(m, channel_id)
        urls = URI.extract(m.message, %w(http https))
        if urls.size > 3
          m.reply "Don't be an asshole #{m.user.nick}"
          m.channel.kick m.user.nick
          return
        end
        urls.sort.uniq.each do |u|
          rep = Url.heard(u, m.user.nick, channel_id).display_for(m.user.nick)
          m.reply rep
        end
      end
    end
  end
end
