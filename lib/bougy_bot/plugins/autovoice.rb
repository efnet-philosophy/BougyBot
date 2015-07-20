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
      match(/voice ([^\s]*)$/, method: :voice)
      match(/devoice ([^\s]*)$/, method: :devoice)
      enable_authentication

      def initialize(*args)
        super
        @autovoice = false
      end

      def listen(m)
        return if m.user.nick == bot.nick
        m.channel.voice(m.user) if @autovoice
      end

      def voice(m, option)
        return unless authenticated?(m, [:subops, :admins])
        if user = m.channel.users.keys.detect { |k| k.nick == option }
          m.channel.voice(user.nick)
        end
      rescue => e
        m.reply "Error: #{e}"
      end

      def devoice(m, option)
        return unless authenticated?(m, [:subops, :admins])
        if user = m.channel.users.keys.detect { |k| k.nick == option }
          m.channel.devoice(user.nick)
        end
      rescue => e
        m.reply "Error: #{e}"
      end

      def execute(m, option)
        return unless authenticated?(m, [:subops, :admins])
        @autovoice = option == 'on'

        m.reply "Autovoice is now #{@autovoice ? 'enabled' : 'disabled'}"
      end
    end
  end
end
