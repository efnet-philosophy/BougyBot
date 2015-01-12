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
      @quotes = (0..3).to_a.map do |_|
        BougyBot::Quote.sample
      end
      @bot.configure do |c|
        c.server = @server
        c.channels = @channels
                             
        c.plugins.plugins = [::Cinch::Plugins::Haiku,
                             ::Cinch::Plugins::CleverBot,
                             BougyBot::Plugins::Functions,
                             BougyBot::Plugins::Autovoice,
                             BougyBot::Plugins::Title,
                             BougyBot::Plugins::QuoteR]
        
        c.nicks = [BougyBot.options[:nick], *@quotes.map { |q| q.author.split.last[0,9].downcase }].compact
        c.user = @quotes.sample.author.split.first.downcase
        c.realname = @quotes.sample.display
        c.local_host = '2001:19f0:300:26e5:aaaa:bbbb:cccc:dddd'
      end
      @configured = true
    end

    def start
      configure unless @configured
      @bot.start
    end
  end
end
