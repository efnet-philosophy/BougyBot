require 'cinch'
# Give this bot ops in a channel and it'll auto voice
# visitors
#
# Enable with !autovoice on
# Disable with !autovoice off
module BougyBot
  # Plugin Namespace
  module Plugins
    # The autovoice functions
    class Autovoice
      include Cinch::Plugin
      listen_to :join
      match(/autovoice (on|off)$/)

      def initialize(*args)
        super
        @autovoice = 'on'
      end

      def listen(m)
        return unless m.user.nick == bot.nick
        m.channel.voice(m.user) if @autovoice
      end

      def execute(m, option)
        return unless m.user.nick.match(/bougyman|Death_Syn/)
        @autovoice = option == 'on'

        m.reply "Autovoice is now #{@autovoice ? 'enabled' : 'disabled'}"
      end
    end
  end
end
