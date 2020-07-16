require 'cinch'
require 'json'
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

      FILTERED_TOPICS = [ /nigger/i ].freeze
      FILTERED_NICKS = [ /chiyou/ ].freeze

      def load_topic_filters
        default_filters = FILTERED_TOPICS.dup
        bougy = User('bougyman')
        topic_file = Pathname('json/filtered_topics.json').expand_path
        if topic_file.exist?
          loaded_topics = JSON.parse(topic_file.read).map do |r|
            Regexp.compile r, true
          end
          default_filters += loaded_topics
        else
          bougy.send("Could not find #{topic_file}, falling back to #{FILTERED_TOPICS}")
          default_filters
        end
      end

      def filtered_topics
        return @filtered_topics if @filtered_topics

        @filtered_topics = load_topic_filters
        Timer(TIMEOUT) do
          @filtered_topics = load_topic_filters
        end
        @filtered_topics
      end

      def load_nick_filters
        default_filters = FILTERED_NICKS.dup
        bougy = User('bougyman')
        nick_file = Pathname('json/filtered_nicks.json').expand_path
        if nick_file.exist?
          loaded_nicks = JSON.parse(nick_file.read).map do |r|
            Regexp.compile r, true
          end
          default_filters += loaded_nicks
        else
          bougy.send("Could not find #{nick_file}, falling back to #{FILTERED_NICKS}")
          default_filters
        end
      end

      def filtered_nicks
        return @filtered_nicks if @filtered_nicks

        @filtered_nicks = load_nick_filters
        Timer(TIMEOUT) do
          @filtered_nicks = load_nick_filters
        end
        @filtered_nicks
      end

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
      
      def filter_topic!(m)
        bougy = User('bougyman')
        message = m.message
        nick = m.user.nick
        @current_topic ||= "Placeholder topic"
        return true if @current_topic == message

        bougy.send "Filtered nicks: #{filtered_nicks}"
        if filtered_nicks.include? nick
          bougy.send "Found filtered nick: #{nick}"
          m.channel.send("#{nick}: Nice try, no cigar. You lost your privileges")
          m.channel.topic = @current_topic
          return false
        end

        bougy.send "Filtered topics: #{filtered_topics}"
        if filtered_topics.detect { |t| message.match? t }
          bougy.send "Found filtered message: #{message}"
          m.channel.send("#{m.user.nick}: Not a fan of that topic. Try again")
          m.channel.topic = @current_topic
          return false
        end

        @current_topic = message
        false
      rescue => e
        bougy.send "Error: #{e}"
        e.backtrace.each { |err| bougy.send "#{err}" }
        raise
      end

      def listen(m)
        # bougy = User('bougyman')
        # bougy.send "Heard topic #{m}"
        return unless m.command == 'TOPIC'
        return if filter_topic! m
        m.channel.mode '+t'
        Timer(TIMEOUT, shots: 1) do
          m.channel.mode '-t'
        end
      end
    end
  end
end
