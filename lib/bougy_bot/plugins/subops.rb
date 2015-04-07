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
    class Subops
      include ::Cinch::Plugin
      enforce_cooldown
      match(/subops (on|off)$/)
      match(/subops_chatty (on|off)$/, method: :chatty)
      match(/kick (.*)/, method: :kick, group: :subops)

      def initialize(*args)
        super
        @subops = false
        @chatty = true
      end

      def kick(m, msg)
        return unless @subops
        target, message = msg.split(/\s+/, 2)
        return unless allowed_to_kick(m, target)
        message ||= "Kicked by #{m.user}'s request"
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
        requestor = m.channel.users[m.user]
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
          m.reply "#{m.user}: #{requestor} Can't kick another subop: #{kickee.first}" if @chatty # rubocop:disable Metrics/LineLength
          return false
        end unless requestor.include?('o')
        if kickee.last.include? 'o'
          m.reply "#{m.user}: #{requestor} Can't kick an op: #{kickee.first}" if @chatty
          return false
        end
        true
      end

      def nick_to_user(channel, nick)
        channel.users.detect { |(k, _v)| k.nick == nick }
      end
    end
  end
end
