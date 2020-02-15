# frozen_string_literal: true

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
      EXCLUDE_ANNOUNCE = %w[#linuxgeneration].freeze
      OVERSHARING_LIMIT = 5
      include Cinch::Plugin
      include Cinch::Extensions::Authentication
      enforce_cooldown

      listen_to :channel
      match(/^!share_limit (\d+) (.*)$/, method: :share_limit!, use_prefix: false)
      def initialize(*args)
        @abuse = {}
        super
      end

      def listen(m) # rubocop:disable Naming/UncommunicativeMethodParamName
        nick = m.user.nick
        return if nick == bot.nick
        return if nick =~ /^(?:pangaea|GitHub|xbps-builder$|void-packages$)/

        log = do_log m
        title_urls m, log.channel_id
      end

      def do_log(m) # rubocop:disable Naming/UncommunicativeMethodParamName
        ChanLog.heard m.channel, m.user, m.message
      end

      def share_limit
        @share_limit ||= Hash.new(OVERSHARING_LIMIT)
      end

      def share_limit!(m, limit, url) # rubocop:disable Naming/UncommunicativeMethodParamName
        return unless authenticated?(m, %i[subops admins])

        share_limit[url] = limit.to_i
        m.reply "New limit for #{url}: #{share_limit[url]}"
      end

      def title_urls(m, channel_id) # rubocop:disable Naming/UncommunicativeMethodParamName,Metrics/AbcSize,Metrics/MethodLength
        return if EXCLUDE_ANNOUNCE.include? m.channel
        return if m.message =~ /^!/

        urls = URI.extract(m.message, %w[http https])
        return if urls.empty?

        if @abuse[m.user.nick] && Time.now - @abuse[m.user.nick] < 15
          @abuse.delete m.user.nick
          m.channel.kick(m.user.nick, '> 1 link per 10 seconds is not allowed')
        end
        if urls.size > 5
          m.reply "Don't be an asshole #{m.user.nick}"
          m.channel.kick m.user.nick
          return
        end
        urls.sort.uniq.each do |u|
          return m.reply "Don't be a dick, #{m.user.nick}" if u.to_s =~ %r{^https?://$}

          rep = Url.heard(u, m.user.nick, channel_id)
          limit = share_limit[u.to_s]
          msg = "Oversharing. This has been shared > #{share_limit[u.to_s]} times."
          if rep.times > (limit * 2)
            bantime = 60 * rep.times
            nickban = format('%<nick>s!*@*', nick: m.user.nick)
            Timer(2, shots: 1) { m.channel.ban(nickban) }
            Timer(bantime, shots: 1) { m.channel.unban nickban }
            msg << " Dat will be a #{bantime / 60} minute ban"
          end
          m.channel.kick(m.user.nick, msg) if rep.times > share_limit[u.to_s]
          @abuse[m.user.nick] = Time.now
          m.reply rep.display_for(m.user.nick)
        end
      end
    end
  end
end
