require 'cinch'
require 'htmlentities'

module Cinch
  # Plugin Space
  module Plugins
    require 'cleverbot'
    # Cleverbot replies
    class CleverBot
      include Cinch::Plugin

      match(->(m) { /^#{m.bot.nick}[:,]? (.+)|(.+) #{m.bot.nick}/i },
            use_prefix: false)

      listen_to :channel

      def talk_to?(message, nick)
        return false if nick =~ /^usefully/
        u = BougyBot::User[nick: nick]
        u ||= BougyBot::Mask.filter(Sequel.function(:split_part,
                                                    :mask,
                                                    '!',
                                                    1) => nick).first.user rescue nil
        if u.nil?
          BougyBot.t nick
          Timer(300, shots: 1) { BougyBot.t nick }
        end
        BougyBot.options[:talk_to]
          .detect { |n| nick =~ /#{n}/i || message =~ /#{n}/i }
      end

      def should_answer?(m)
        info "should_anser? #{m.message}"
        message = m.message.sub(/ACTION(.*)/, '\1')
        return false if message =~ /^!/
        return false if message =~ /^\./
        return false if message =~ /^(#{bot.nick}|howto)/
        return true if talk_to?(message, m.user.nick)
        chan = BougyBot::Channel.find(name: m.channel.name)
        tenmins = Time.now - (60 * 10)
        how_many = BougyBot::ChanLog.filter(channel_id: chan.id)
                   .filter { at  > tenmins }.count
        r = rand(1000)
        r < case how_many
            when 1..10
              75
            when 10..20
              25
            when 20..30
              7
            when 30..50
              5
            when 50..75
              4
            when 75..100
              2
            else
              1
            end
      end

      def deezify(s)
        @entities.decode s.gsub(/\bthese\b/, 'deez')
      end

      def listen(m)
        return unless should_answer? m
        cbot_reply = if @backoff
                       BougyBot::Quote.best.display
                     else
                       @cleverbot.write(m.message)
                     end
        if cbot_reply =~ /<html><head><title>Apache|(?i:clever)/
          warn 'Bad response from cleverbot, back off!'
          @backoff = true
          Timer(300, shots: 1) { @backoff = nil }
          cbot_reply = BougyBot::Quote.best.display
        elsif cbot_reply =~ /clever/
          warn "Clever response from clever: #{cbot_reply}"
          cbot_reply = BougyBot::Quote.best.display
        end
        Timer(rand(10), shots: 1) { m.reply(format('%s: %s', m.user.nick, deezify(cbot_reply))) }
      end

      def initialize(*args)
        super
        @cleverbot = Cleverbot::Client.new
        @entities  = HTMLEntities.new
      end

      def execute(m, message)
        return if m.user.nick =~ /^usefully/
        msg_back = if @backoff
                     BougyBot::Quote.best.display
                   else
                     @cleverbot.write message
                   end
        if msg_back =~ /<html><head><title>Apache|(?i:clever)/
          warn 'Bad clever response, back off!'
          @backoff = true
          Timer(300, shots: 1) { @backoff = nil }
          msg_back = BougyBot::Quote.best.display
        end
        Timer(rand(5), shots: 1) { m.reply(deezify(msg_back), true) }
      end
    end
  end
end
