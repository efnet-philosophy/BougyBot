require 'cinch'
require 'nokogiri'
require 'open-uri'
require 'cinch/cooldown'
require 'wolfram-alpha'

# Bot Namespace
module BougyBot
  # Plugin namespace
  module Plugins
    # Wolfram Alpha plugin
    class Wolfram
      include Cinch::Plugin
      enforce_cooldown
      match(/((?:what|how|why|who|where) .+)\??/)

      def self.search(query)
        #          https://developer.wolframalpha.com/portal/signin.html
        api_id = BougyBot.options.wolfram_key

        wolfram = WolframAlpha::Client.new(api_id)

        response = wolfram.query(query)
        if response.pods.size > 1
          relevant_pods = response.pods.reject { |n| n.id == 'Input' }
          relevant_pods.map do |result|
            format('%s: %s',
                   result.id,
                   result.subpods.map(&:plaintext).join('; '))
          end.join(':: ').tr("\n", ' ')
        else
          'Sorry, I\'ve no idea'
        end
      end

      def execute(m, query)
        m.reply "#{m.user.nick}: #{self.class.search(query)}"
      end
    end
  end
end
