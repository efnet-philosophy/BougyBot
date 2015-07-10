require 'cinch'
require_relative '../../bougy_bot'
require 'cinch/cooldown'
BougyBot::M 'quote'

# Bot Namespace
module BougyBot
  # Plugin Namespace
  module Plugins
    # Quote Function
    class QuoteR
      @all   = []

      def self.all
        @all
      end
      # rubocop:enable Style/TrivialAccessors

      include ::Cinch::Plugin
      enforce_cooldown
      match(/q(?: ?(.*))?$/, method: :quote)
      match(/(?:countq)$/, method: :count)

      def initialize(*args)
        super
      end

      def count(m)
        m.reply "Currently #{Quote.summary}"
      end

      def quote(m, query)
        return m.reply Quote.sample.display if query.nil? || query == ''
        m.reply Quote.best(query).display
      rescue => e
        log 'Died on quote!', :warn
        log e.to_s, :warn
        m.reply "#{m.user.nick}: No dice"
      end
    end
  end
end
