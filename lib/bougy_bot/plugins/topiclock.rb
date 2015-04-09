require 'cinch'
# Lock the topic for 2 minutes after a topic change
module BougyBot
  # Plugin Namespace
  module Plugins
    # The topiclock functions
    class Topiclock
      include ::Cinch::Plugin
      match(/tlock (on|off)$/)
      listen_to :topic

      def initialize(*args)
        super
        @tlock = true
        @topic = false
      end

      def execute(m, option)
        return unless m.user.nick.match(/bougyman|Death_Syn/)
        @tlock = option == 'on'
        m.reply "Topic Unlocking is now #{@tlock ? 'enabled' : 'disabled'}"
      end

      def listen(m)
        return if @topic
        return unless m.command == 'TOPIC'
        @topic = true
        m.channel.mode '+t'
        Timer(120) do
          m.channel.mode '-t'
          @topic = false
        end
      end
    end
  end
end
