# frozen_string_literal: true
#
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
      EXCLUDE_ANNOUNCE = %w(#linuxgeneration).freeze
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
        return if EXCLUDE_ANNOUNCE.include? m.channel
        urls = URI.extract(m.message, %w(http https))

        if urls.size > 5
          m.reply "Don't be an asshole #{m.user.nick}"
          m.channel.kick m.user.nick
          return
        end
        urls.sort.uniq.each do |u|
          return m.reply "Don't be a dick, #{m.user.nick}" if u.to_s =~ %r{^https?://$}
          rep = Url.heard(u, m.user.nick, channel_id).display_for(m.user.nick)
          m.reply rep
        end
      end
    end
  end
end
