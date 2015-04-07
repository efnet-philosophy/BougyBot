require 'cinch'
# Lock the topic for 2 minutes after a topic change
module BougyBot
  # Plugin Namespace
  module Plugins
    # The topiclock functions
    class Topiclock
      include ::Cinch::Plugin
      listen_to :topic

      def listen(m)
        return unless m.command == 'TOPIC'
        m.channel.mode '+t'
        Timer(120) { m.channel.mode '-t' }
      end
    end
  end
end
