require 'cinch'
require 'cinch/cooldown'
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
        'Saturday Night Disco'
      ]
      include ::Cinch::Plugin
      enforce_cooldown
      match(/subops (on|off)$/)
      match(/subops_chatty (on|off)$/, method: :chatty)
      match(/(?:kick|battle)[^\s]* (.*)/, method: :kick, group: :subops)
      match(/ban[^\s]* (.*)/, method: :ban, group: :subops)
      match(/dance[^\s]* (.*)/, method: :danceoff, group: :subops)

      def initialize(*args)
        super
        @subops = true
        @chatty = true
      end

      def danceoff(m, msg)
        return unless @subops
        target, message = msg.split(/\s+/, 2)
        kicker = m.user
        return if kicker.nick =~ /^#{target}$/i
        kickee = nick_to_user(m.channel, target)
        return unless kickee
        m.reply "#{kicker.nick} Challenges #{target} to a Dance Off" if @chatty
        Timer(5, shots: 1) do
          results = voice_versus_voice(m.channel, kicker, kickee, 'Dance Off', DANCES.sample)
          if results
            winmsg = "#{kicker.nick} prevails with '#{message}' of #{results.first} to #{target}'s #{results.last}"
            m.channel.kick target, winmsg
          end
        end
      end

      def ban(m, msg)
        return unless @subops
        target, message = msg.split(/\s+/, 2)
        return if m.user.nick =~ /^#{target}$/i
        res = allowed_to_kick(m, target)
        return unless res
        if res.respond_to? :last
          message ||= "Kicked by #{m.user}'s request"
          message << "No banning of subops, but you did win a Kick -> (#{res.first} > #{res.last})" if res.respond_to? :first
          m.channel.kick target, message
        else
          message ||= "Banned by #{m.user}'s request"
          banee = nick_to_user(m.channel, target)
          ip = banee.first.mask.mask.split('@').last
          nickban = format('%s!*@*', target)
          m.channel.kick target, message
          m.channel.ban nickban
          m.channel.ban format('*!*@%s', ip)
        end
      end

      def kick(m, msg)
        return unless @subops
        target, message = msg.split(/\s+/, 2)
        return if m.user.nick =~ /^#{target}$/i
        res = allowed_to_kick(m, target)
        return unless res
        message ||= "Kicked by #{m.user}'s request"
        message << " (#{res.first} > #{res.last})" if res.respond_to? :first
        m.channel.kick target, message
      end

      def chatty(m, option)
        return unless m.user.nick.match(/bougyman|Death_Syn/)
        @chatty = option == 'on'
        m.reply "Subops Verbosity is now #{@chatty ? 'enabled' : 'disabled'}"
      end

      def execute(m, option)
        return unless m.user.nick.match(/bougyman|Death_Syn/)
        @subops = option == 'on'
        m.reply "Subops is now #{@subops ? 'enabled' : 'disabled'}"
      end

      private

      # TODO: Fill this out with more logic
      def allowed_to_kick(m, target) # rubocop:disable all
        kicker = m.user
        requestor = m.channel.users[kicker]
        unless requestor
          m.reply "No Requestor Found, wtf, #{m.user}?" if @chatty
          return false
        end
        unless requestor.include?('v') || requestor.include?('o')
          m.reply "No v or o for #{m.user}: #{requestor}" if @chatty
          return false
        end
        kickee = nick_to_user(m.channel, target)
        unless kickee
          m.reply "#{target} is gone or chagned nicks" if @chatty
          return false
        end
        if kickee.last.include? 'v'
          m.reply "#{kicker.nick}: Battle initiated with #{target}" if @chatty # rubocop:disable Metrics/LineLength
          return voice_versus_voice(m.channel, kicker, kickee)
        end unless requestor.include?('o')
        if kickee.last.include? 'o'
          m.reply "#{m.user}: #{requestor} Can't kick an op: #{kickee.first}" if @chatty
          m.channel.kick "#{kicker.nick}", "Lost battle to #{target}'s impenetrable '@' defense"
          return false
        end
        true
      end

      def voice_versus_voice(channel, kicker, kickee, ftype = 'battle', fdefense = 'defense')
        if kickee.last.include? 'o'
          channel.kick "#{kicker.nick}", "Lost #{ftype} to #{kickee.first.nick}'s impenetrable '@' #{fdefense}"
          return false
        end
        # TODO: write some better battle logic
        kicker_points = rand(64)
        kickee_points = rand(64)
        if kickee_points > kicker_points
          channel.kick "#{kicker.nick}",
                       "Lost #{ftype} to #{kickee.first.nick}'s strong #{fdefense}: #{kickee_points} > #{kicker_points}"
          return false
        end
        [kicker_points, kickee_points]
      end

      def nick_to_user(channel, nick)
        channel.users.detect { |(k, _v)| k.nick =~ /#{nick}/i }
      end
    end
  end
end
