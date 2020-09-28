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

      MATH_MAPS = {
        :* => %w{times thymes timez multiplied_by myltiply},
        :- => %w{minus mynus subtracted_from subtract},
        :+ => %w{plus add added_to phlus},
      }
      ANSWERS = {}
      AUTHORS = BougyBot::Quote.distinct(:author).where(author: /^\w[\w ]*$/).select_map(:author)

      listen_to :join, method: :listen
      listen_to :devoice, method: :devoiced
      match(/autovoice(?: (on|off))?$/)
      match(/voice ([^\s]*)$/, method: :voice)
      match(/voiceme (.*)?$/, method: :voiceme)
      match(/devoice ([^\s]*)$/, method: :devoice)
      match(/\+m$/, method: :moderate)
      match(/\-m$/, method: :unmoderate)
      match(/\+t$/, method: :lock_topic)
      match(/\-t$/, method: :unlock_topic)
      enable_authentication

      def initialize(*args)
        super
        @autovoice = true
        @devoiced_users = []
      end

      def devoiced(m, user)
        @devoiced_users << user unless @devoiced_users.include? user
        Timer(600, shots: 1) { @devoiced_users.delete user if @devoiced_users.include? user }
      end

      def math_problem(nick)
        op = MATH_MAPS.keys.sample
        num1, num2 = rand(100), rand(100)
        answer = num1.send(op, num2)
        ANSWERS[nick] = answer
        [MATH_MAPS[op].sample, num1, num2, answer]
      end

      def quote_author(nick)
        author = AUTHORS.sample
        q = BougyBot::Quote.where(author: author).select_map(:quote).sample
        all_authors = [author, AUTHORS.sample, AUTHORS.sample, AUTHORS.sample, AUTHORS.sample, AUTHORS.sample]
        ANSWERS[nick] = author
        [q, *all_authors.sort_by { |_, _| rand(100) <=> rand(100) } ]
      end

      def set_voice_timer(m, user)
        if @devoiced_users.include? user
          return m.reply "!!! #{user.nick} is currently not being autovoiced due to 'reasons'. Please do not voice (or op) this user !!!"
        end
        randt = rand(60)
        time = randt
        time = (randt + 100) if user.mask.to_s =~ /@(?:[\d\.]+$|:)/
        warn "Setting voice timer for #{user.nick} (#{user.mask} to #{time}"
        Timer(time, shots: 1) { voice_nick(m.channel, user.nick) }
      end

      def listen(m)
        user = m.user
        return if user.nick =~ /hiyou/
        return if user.nick == bot.nick

        nick = user.nick
        warn "#{user.nick} joined #{m.channel}"
        set_voice_timer(m, user) if @autovoice
        u = User.find nick: nick
        m.reply("<#{nick}> #{u.tagline}") if u.tagline
      end

      def voice_nick(channel, nick)
        found_user = channel.users.detect { |k| k.first.nick == nick }
        return unless found_user
        return if found_user.last.include? 'v'

        channel.voice(nick)
      end

      def voice(m, option)
        return unless authenticated?(m, [:subops, :admins])
        if user = m.channel.users.keys.detect { |k| k.nick == option }
          m.channel.voice(user.nick)
        end
      rescue => e
        m.reply "Error: #{e}"
      end

      def moderate(m)
        return unless authenticated?(m, [:subops, :admins])
        m.channel.mode('+m')
      rescue => e
        m.reply "Error: #{e}"
      end

      def unmoderate(m)
        return unless authenticated?(m, [:subops, :admins])
        m.channel.mode('-m')
      rescue => e
        m.reply "Error: #{e}"
      end

      def lock_topic(m)
        return unless authenticated?(m, [:subops, :admins])
        m.channel.mode('+t')
      rescue => e
        m.reply "Error: #{e}"
      end

      def unlock_topic(m)
        return unless authenticated?(m, [:subops, :admins])
        m.channel.mode('-t')
      rescue => e
        m.reply "Error: #{e}"
      end

      def voiceme(m, answer)
        user = m.user
        correct_answer = ANSWERS[user.nick]
        return unless correct_answer
        channels = m.bot.channels.select { |c| c.users.detect { |u|  u.first.nick == user.nick } }
        channels.each do |chan|
          next unless chan.name == '#philosophy'
          found_user = chan.users.detect { |t| t.first.nick == user.nick }
          if found_user
            if found_user.last.include? 'v'
              m.reply "You fucking twat, you already have voice in #{chan.name}, what more do you need?"
              return
            end
            correct = false
            if correct_answer.is_a? Integer
              correct = true if answer.to_i == correct_answer
            else
              correct = true if correct_answer.downcase == answer.downcase
            end
            if correct
              chan.voice user.nick
            else
              m.reply 'That is an incorrect answer, iq test failed. No voice for you!'
              chan.kick user.nick, 'Failed IQ Test'
            end
          else
            m.reply 'Voice you where? You are not in any channels I am in, dumbass'
            return
          end
        end
      rescue => e
        m.reply "Error: #{e}"
        m.reply e.backtrace.join("\n")
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
