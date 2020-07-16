# frozen_string_literal: true

require 'cinch'
require_relative '../../bougy_bot'
require 'cinch/cooldown'

module BougyBot
  module Plugins
    # Cinch Plugin to send notes
    class Covid
      include Cinch::Plugin
      enforce_cooldown

      match(/^`c(.+)/, method: :covid, use_prefix: false)

      def covid(m, message) # rubocop:disable Naming/UncommunicativeMethodParamName
        place = message
      rescue StandardError => e
        m.reply "Error getting data for #{messsage}"
        m.user.send e
        e.backtrace.each do |err|
          m.user.send err
        end
      end

      private

      def send_notes(m) # rubocop:disable Naming/UncommunicativeMethodParamName
        m.reply
      end
    end
  end
end
