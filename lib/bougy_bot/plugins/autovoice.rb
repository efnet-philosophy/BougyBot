require 'cinch'

# Give this bot ops in a channel and it'll auto voice
# visitors
#
# Enable with !autovoice on
# Disable with !autovoice off

class Autovoice
  include Cinch::Plugin
  listen_to :join
  match(/autovoice (on|off)$/)

  def initialize(*args)
    super
    @autovoice = "on"
  end
  def listen(m)
    unless m.user.nick == bot.nick
      m.channel.voice(m.user) if @autovoice
    end
  end

  def execute(m, option)
    return unless m.user.nick.match(/bougyman|Death_Syn/)
    @autovoice = option == "on"

    m.reply "Autovoice is now #{@autovoice ? 'enabled' : 'disabled'}"
  end
end

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
