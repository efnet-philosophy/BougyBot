# frozen_string_literal: true
require 'cinch'
require 'cinch/cooldown'
require 'ostruct'
# Subops stuff
#
# Enable with !subops on
# Disable with !subops off
module BougyBot
  # Plugin Namespace
  module Plugins
    # The subop functions
    class Subops # rubocop:disable all
      DANCES = [
        'wicked break dance',
        'Rumba',
        'Sexy Samba',
        'Classic Waltz',
        'Dazzling Ballet',
        'Jawdropping Modern Masterpiece',
        'Sultry Tango',
        'Swayze-Like Moves',
        'Saturday Night Disco',
        'Moves like Jagger',
        'Wild Modern Jazz',
        'Captivating Flamenco',
        'Thrilling Cha-Cha',
        'Foxy Foxtrot'
      ].freeze
      include ::Cinch::Plugin
      include Cinch::Extensions::Authentication
      enforce_cooldown
      match(/subops (on|off)$/)
      match(/subops_chatty (on|off)$/, method: :chatty)
      match(/punish ([^\s]+)$/, method: :punish)
      match(/unpunish ([^\s]+)$/, method: :unpunish)
      match(/(?:kick|battle)[^\s]* (.*)/, method: :kick, group: :subops)
      match(/ban[^\s]* (.*)/, method: :ban, group: :subops)
      match(/dance[^\s]* (.*)/, method: :danceoff, group: :subops)
      match(/^(\w+):\s+drop a bomb on\s+(.*)?$/, method: :bomb, use_prefix: false)
      enable_authentication

      def initialize(*args)
        super
        @subops = true
        @chatty = false
        @protected = []
        @punished  = [/bandini/]
        @ignored = ['howto']
      end

      def danceoff(m, msg)
        return m.action DANCES.sample

        return if authenticated? m, :enemies
        return unless @subops
        return if @ignored.include? m.user.nick
        if @punished.detect { |p| p.match m.user.nick }
          m.channel.kick m.user.nick, 'You have lost this privilege, please stop.'
          return false
        end
        target, message = msg.split(/\s+/, 2)
        kicker = m.user
        return if kicker.nick =~ /^#{target}$/i
        kickee = nick_to_user(m.channel, target)
        return unless kickee
        m.reply "#{kicker.nick} Challenges #{target} to a Dance Off" if @chatty
        Timer(5, shots: 1) do
          results = voice_versus_voice(m, kicker, kickee, 'Dance Off', DANCES.sample)
          if results
            winmsg = "#{kicker.nick} prevails with '#{message}' of #{results.first} to #{target}'s #{results.last}"
            m.channel.kick target, winmsg
          end
        end
      end

      def bomb(m, me, msg)
        return unless me == bot.nick
        nick, rest = msg.split(/\s+/, 2)
        return unless m.channel.users.keys.detect { |u| u.nick == nick }
        Timer(3, shots: 1) { m.channel.action "Swoops over #{nick}" }
        Timer(5, shots: 1) do
          if rand(10) > 6
            m.channel.action 'Drops a BIG BAN BOMB'
            ban m, msg
          else
            m.channel.action "Drops a lil' kick bomb"
            kick m, msg
          end
        end
      end

      def ban(m, msg) # rubocop:disable all
        return unless authenticated?(m, [:subops, :admins])
        return if @ignored.include? m.user.nick
        target, message = msg.split(/\s+/, 2)
        return if m.user.nick =~ /^#{target}$/i
        res = allowed_to_kick(m, target)
        return unless res
        Log.info "#{target} banned by #{res} (as #{m.user})"
        if res.respond_to? :last
          message ||= "Kicking by #{m.user}'s request: "
          if res.first > res.last
            message = "#{messsage} No banning of subops, but you did win a Kick -> (#{res.first} > #{res.last})"
            m.channel.kick target, message
          else
            message = "#{message} No banning of subops, #{m.user.nick}, you loser -> (#{res.last} > #{res.first})"
            m.channel.kick m.user.nick, message
          end
        else
          message ||= "Banned by #{m.user}'s request"
          banee = nick_to_user(m.channel, target)
          ip = banee.first.mask.mask.split('@').last
          nickban = format('%s!*@*', target)
          m.channel.kick target, message
          m.channel.ban nickban
          m.channel.ban format('*!*@%s', ip)
          Timer(60 * 60 * 2, shots: 1) do
            m.channel.unban nickban
            m.channel.unban format('*!*@%s', ip)
          end
        end
      rescue => e
        m.user.send "Error banning: #{e}"
        e.backtrace.each { |err| m.user.send err }
      end

      def kick(m, msg)
        return unless authenticated?(m, [:subops, :admins])
        return unless @subops
        return if @ignored.include? m.user.nick
        target, message = msg.split(/\s+/, 2)
        return if m.user.nick =~ /^#{target}$/i
        res = allowed_to_kick(m, target)
        return unless res
        message ||= "Kicked by #{m.user}'s request"
        message << " (#{res.first} > #{res.last})" if res.respond_to? :first
        m.channel.kick target, message
      end

      def chatty(m, option)
        return unless authenticated?(m, :admins)
        @chatty = option == 'on'
        m.reply "Subops Verbosity is now #{@chatty ? 'enabled' : 'disabled'}"
      end

      def unpunish(m, option)
        return unless authenticated?(m, :admins)
        if idx = @punished.find_index(/#{option}/)
          @punished.delete(@punished[idx])
          m.reply "Unpunished #{option}"
        else
          m.reply "#{option} is not punished"
        end
      end

      def punish(m, option)
        return unless authenticated?(m, :admins)
        @punished << /#{option}/
        m.reply 'Done'
      end

      def execute(m, option)
        return unless authenticated?(m, :admins)
        @subops = option == 'on'
        m.reply "Subops is now #{@subops ? 'enabled' : 'disabled'}"
      end

      private

      # TODO: Fill this out with more logic
      def allowed_to_kick(m, target) # rubocop:disable all
        binding.pry if @chatty # rubocop:disable all
        if @protected.include? target
          m.channel.kick m.user.nick, "Cool down, #{m.user.nick}, you're trying some abuse, here."
          return false
        end
        if @punished.detect { |p| p.match m.user.nick }
          m.channel.kick m.user.nick, 'You have lost this privilege, please stop.'
          return false
        end
        kicker = m.user
        auth_user = bot.config.authentication.logged_in.detect { |(k, _v)| k == kicker }
        return false unless auth_user
        return true if kicker.nick == 'xartet'

        kickee = nick_to_user(m.channel, target)
        unless kickee
          if @chatty
            kicker.msg "#{target} is gone or changed nicks"
          else
            m.reply "#{target} is gone or changed nicks"
          end
          return false
        end
        kickee_user = current_user(OpenStruct.new(user: kickee.first))
        binding.pry if @chatty # rubocop:disable  Lint/Debugger
        if kickee.last.include?('v') || (kickee_user && kickee_user.level == 'subop')
          m.reply "#{kicker.nick}: Battle initiated with #{target}" if @chatty # rubocop:disable Metrics/LineLength
          return voice_versus_voice(m, kicker, kickee)
        end unless authenticated?(m, :admins)
        binding.pry if @chatty
        if kickee.last.include?('o') || (kickee_user && kickee_user.level == 'admin')
          if @chatty
            m.reply "#{m.user}: #{auth_user.level} Can't kick an op: #{kickee.first}"
          else
            kicker.msg "#{m.user}: #{auth_user.level} Can't kick an op: #{kickee.first}"
          end
          m.channel.kick "#{kicker.nick}", "Lost battle to #{target}'s impenetrable '@' defense"
          return false
        end
        binding.pry if @chatty
        @protected << target
        Timer(30, shots: 1) { @protected.delete target }
        auth_user
      end

      def voice_versus_voice(m, kicker, kickee, ftype = 'battle', fdefense = 'defense')
        channel = m.channel
        if kickee.last.include? 'o'
          @protected << kickee.first.nick
          Timer(30, shots: 1) { @protected.delete kickee.first.nick }
          channel.kick "#{kicker.nick}", "Lost #{ftype} to #{kickee.first.nick}'s impenetrable '@' #{fdefense}"
          return false
        end
        return true if authenticated? m, :admins
        # TODO: write some better battle logic, take into account karma?
        kicker_points = rand(64)
        kickee_points = rand(64)
        if kickee_points > kicker_points
          @protected << kicker.nick
          Timer(30, shots: 1) { @protected.delete kicker.nick }
          channel.kick "#{kicker.nick}",
                       "Lost #{ftype} to #{kickee.first.nick}'s strong #{fdefense}: #{kickee_points} > #{kicker_points}"
          return false
        end
        @protected << kickee.first.nick
        Timer(30, shots: 1) { @protected.delete kickee.first.nick }
        [kicker_points, kickee_points]
      end

      def nick_to_user(channel, nick)
        channel.users.detect { |(k, _v)| k.nick =~ /#{Regexp.escape(nick)}/i }
      end
    end
  end
end
