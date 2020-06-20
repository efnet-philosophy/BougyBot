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

      FILTERED_TOPICS = [ /nigger/ ].freeze
      FILTERED_NICKS = %w{chiyou}.freeze

      def load_topic_filters
        if File.exist?('json/filtered_topics.json')
          loaded_nicks = JSON.parse(File.read('json/filtered_topics.json')).map do |r|
            Regexp.compile r
          end
          FILTERED_NICKS.dup << loaded_nicks
        else
          FILTERED_TOPICS.dup
        end
      end

      def filtered_topics
        return @filtered_topics if @filtered_topics

        @filtered_topics = load_topic_filters
        Timer(300) do
          @filtered_topics = load_topic_filters
        end
        @filtered_topics
      end

      def load_nick_filters
          if File.exist?('json/filtered_nicks.json')
            loaded_nicks = JSON.parse(File.read('json/filtered_nicks.json'))
            FILTERED_NICKS.dup << loaded_nicks
          else
            FILTERED_NICKS.dup
          end
      end

      def filtered_nicks
        return @filtered_nicks if @filtered_nicks

        @filtered_nicks = load_nick_filters
        Timer(300) do
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
        if filtered_nicks.include? nick
          bougy.send "Checking filtered nicks. nick is #{nick}"
          m.channel.send("#{nick}: Nice try, no cigar. You lost your privileges")
          m.channel.topic = @current_topic
          return false
        end
        if filtered_topics.detect { |t| message.match? t }
          bougy.send "Checking filtered messages. message is #{message}"
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
