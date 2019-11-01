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

      listen_to :join
      match(/autovoice (on|off)$/)
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
        @autovoice = false
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

      def listen(m)
        user = m.user
        return if user.nick == bot.nick
        if @autovoice
          nick = user.nick
          time = 30
          time = 120 if user.mask.to_s =~ /@(?:[\d\.]+$|:)/
          warn "Setting voice timer for #{nick} (#{user.mask} to #{time}"
          Timer.new(time, shots: 1) { m.channel.voice(nick) }
        else
          return unless m.channel.name == '#philosophy'
          # m.user.msg 'Hey, we are moderated because dionysus is an asshat. If you want voice, ask in #pho:'
          # if user.host !~ /^\d+\.\d+\.\d+\.\d+$/
          #   op, num1, num2, answer = math_problem(user.nick)
          #   m.user.msg 'Hey, we are moderated because dionysus is an asshat. If you want voice, you must solve the math problem:'
          #   m.user.msg "What is #{num1} #{op} #{num2}?"
          # else
          #   begin
          #     #quote = quote_author(user.nick)
          #     #m.user.msg "Who said '#{quote.shift}'?"
          #     #m.user.msg "Choices are: #{quote.join(', ')}"
          #   rescue => e
          #     if m.user.nick =~ /^bougy/
          #       m.user.msg e
          #       m.user.msg e.backtrace.join('\n')
          #     end
          #   end
          # end
          #m.user.msg "/msg #{bot.nick} !voiceme <theanswer> to me for voice."
        end
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
