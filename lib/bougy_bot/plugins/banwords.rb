require 'cinch'
require 'nokogiri'
require 'open-uri'
require 'cinch/cooldown'

# Bot Namespace
module BougyBot
  # Plugin namespace
  module Plugins
    # Title & Url shortening bot
    class BanWords
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
        check_banlist m
      end

      def check_banlist(m)
        channel = Channel.from_m(m)
        bannables = BanList.where(channel_id: channel.id).where("#{m.message} ~ matcher")
        ban_the_fuck_out_of(m, bannables) if bannables.count > 0
      end

      def ban_the_fuck_out_of(m, bannables)
        m.channel.msg "#{m.user.nick}: you should be banned for that #{bannables.first.matcher}"
      end
    end
  end
end
