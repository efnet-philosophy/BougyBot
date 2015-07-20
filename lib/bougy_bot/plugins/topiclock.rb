require 'cinch'
# Lock the topic for 2 minutes after a topic change
module BougyBot
  # Plugin Namespace
  module Plugins
    # The topiclock functions
    class Topiclock
      include ::Cinch::Plugin
      include ::Cinch::Extensions::Authentication
      TIMEOUT = 360
      match(/tlock (on|off)$/)
      match(/topic (.*)$/, method: :topic)
      listen_to :topic

      def initialize(*args)
        super
        @tlock = true
      end

      def topic(m, option)
        return unless authenticated? m
        m.channel.topic = option
        #m.channel.mode '+t'
        #Timer(TIMEOUT, shots: 1) do
        #  m.channel.mode '-t'
        #end
      rescue => e
        m.reply e
      end

      def execute(m, option)
        return unless m.user.nick.match(/bougyman|Death_Syn/)
        @tlock = option == 'on'
        m.reply "Topic Unlocking is now #{@tlock ? 'enabled' : 'disabled'}"
      end

      def listen(m)
        return unless m.command == 'TOPIC'
        m.channel.mode '+t'
        Timer(TIMEOUT, shots: 1) do
          m.channel.mode '-t'
        end
      end
    end
  end
end
