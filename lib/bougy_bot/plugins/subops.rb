require 'cinch'
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
      match(/subops (on|off)$/)
      match(/kick (.*)/, method: :kick, group: :subops)

      def initialize(*args)
        super
        @subops = false
      end

      def kick(m, target, message = nil)
        return unless @subops
        return unless allowed_to_kick(m, target)
        message ||= "Kicked by #{m.user}'s request"
        m.channel.kick target, message
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
        m.reply 'No Requestor Found' unless requestor
        return false unless requestor
        m.reply "No v for requestor #{requestor}" unless requestor.include? 'v'
        return false unless requestor.include? 'v'
        kickee = nick_to_user(m.channel, target)
        m.reply "#{target} is gone or chagned nicks" unless kickee
        return false unless kickee
        m.reply "#{m.user}: #{requestor} Can't kick an op: #{kickee.first}" if kickee.last.include? 'o' # rubocop:disable Metrics/LineLength
        return false if kickee.last.include? 'o'
        true
      end

      def nick_to_user(channel, nick)
        channel.users.detect { |(k, _v)| k.nick == nick }
      end
    end
  end
end
