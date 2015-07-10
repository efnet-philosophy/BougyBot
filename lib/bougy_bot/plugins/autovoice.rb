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
      include ::Cinch::Plugin
      include Cinch::Extensions::Authentication

      listen_to :join
      match(/autovoice (on|off)$/)
      enable_authentication


      def initialize(*args)
        super
        @autovoice = false
      end

      def listen(m)
        return if m.user.nick == bot.nick
        m.channel.voice(m.user) if @autovoice
      end

      def execute(m, option)
        return unless authenticated?(m, [:subops, :admins])
        @autovoice = option == 'on'

        m.reply "Autovoice is now #{@autovoice ? 'enabled' : 'disabled'}"
      end
    end
  end
end
