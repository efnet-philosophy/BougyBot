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
    end

    def abuse?(nick)
      now = Time.now
      @abuse[nick] ||= []
      @abuse[nick].unshift now
      @abuse[nick] = @abuse[nick][0,10].compact
      @abuse[nick].select { |t| now - t < 180 }.size > 5
    end

    def abused
      now = Time.now
      @uses.unshift now
      @uses = @uses[0.35].compact
      @uses.select { |t| now - t < 180 }.size > 30
    end

    def listen(m)
      nick = m.user.nick
      return if abuse? nick
      return if abused
      return if nick == bot.nick
      urls = URI.extract(m.message, %w(http https))
      urls.each do |u|
        m.reply Url.heard(u, nick).display_for(nick)
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
