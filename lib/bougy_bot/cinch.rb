require_relative '../bougy_bot'
require 'cinch'
require_relative './plugins/functions'
require_relative './plugins/autovoice'
require_relative './plugins/title'
require_relative './plugins/quote'
require_relative './plugins/cleverbot.rb'
require_relative './plugins/haiku.rb'
# Bot Namespace
module BougyBot
  # The Cinch part
  class Cinch
    attr_reader :bot
    def initialize(server = nil, channels = nil)
      @server = server || '2001:19f0::dead:beef:cafe'
      @bot = ::Cinch::Bot.new
      @channels = channels || ['#pho', '#philrobot']
    end

    def configure
      @bot.configure do |c|
        c.server = @server
        c.channels = @channels
                             
        c.plugins.plugins = [::Cinch::Plugins::Haiku,
                             ::Cinch::Plugins::CleverBot,
                             BougyBot::Plugins::Functions,
                             BougyBot::Plugins::Autovoice,
                             BougyBot::Plugins::Title,
                             BougyBot::Plugins::QuoteR]
        c.nick = BougyBot.options[:nick] || 'phillip'
        c.user = 'phillip'
        c.realname = 'phil'
        c.local_host = '2001:19f0:300:26e5::efff'
      end
      @configured = true
    end

    def start
      configure unless @configured
      @bot.start
    end
  end
end
