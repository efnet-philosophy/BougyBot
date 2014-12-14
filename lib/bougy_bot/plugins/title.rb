require 'cinch'
require 'nokogiri'
require 'open-uri'

# Give this bot ops in a channel and it'll auto voice
# visitors
#
# Enable with !autovoice on
# Disable with !autovoice off

module BougyBot
  # Title & Url shortening bot
  class Title
    include Cinch::Plugin

    listen_to :channel
    def initialize(*args)
      @abuse = {}
      @uses  = []
      super
    end

    def abuser?(nick)
      now = Time.now
      @abuse[nick] ||= []
      @abuse[nick] << now
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
      return if nick =~ /^(?:GitHub|xbps-builder$|void-packages$)/
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

__END__
=begin
bot = Cinch::Bot.new do
  configure do |c|
    c.nick            = "cinch_autovoice"
    c.server          = "irc.freenode.org"
    c.channels        = ["#cinch-bots"]
    c.verbose         = true
    c.plugins.plugins = [Autovoice]
  end
end

bot.start
=end
