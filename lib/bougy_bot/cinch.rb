require_relative '../bougy_bot'
require 'cinch'
require_relative './plugins/functions'
require_relative './plugins/autovoice'
require_relative './plugins/title'
require_relative './plugins/quote'
require_relative './plugins/cleverbot.rb'
require_relative './plugins/haiku.rb'
require "cinch-weatherman"
require "cinch-convert"
require "cinch-calculate"
require "cinch/plugins/news"
require "cinch/plugins/evalso"
require "cinch-karma"
require "cinch-urbandict"
require "cinch-dicebag"
require "cinch/plugins/fortune"
require "cinch/plugins/wikipedia"

require 'open-uri'
require 'nokogiri'
require 'cgi'
class Google
  include Cinch::Plugin
  match /google (.+)/
  def search(query)
    url = "http://www.google.com/search?q=#{CGI.escape(query)}"
    res = Nokogiri::HTML(open(url)).at("h3.r")
    title = res.text
    link = res.at('a')[:href]
    desc = res.at("./following::div").children.first.text
    CGI.unescape_html "#{title} - #{desc} (#{link})"
  rescue
    "No results found"
  end
  def execute(m, query)
    m.reply(search(query))
  end
end

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
                             ::Cinch::Plugins::Convert,
                             ::Cinch::Plugins::Calculate,
                             ::Cinch::Plugins::Karma,
                             ::Cinch::Plugins::UrbanDict,
                             ::Cinch::Plugins::EvalSo,
                             ::Cinch::Plugins::News,
                             ::Cinch::Plugins::Wikipedia,
                             ::Cinch::Plugins::Dicebag,
                             ::Cinch::Plugins::Fortune,
                             ::Cinch::Plugins::Weatherman,
                             ::Google,
                             BougyBot::Plugins::Functions,
                             BougyBot::Plugins::Autovoice,
                             BougyBot::Plugins::Title,
                             BougyBot::Plugins::QuoteR]
        
        c.nicks = [BougyBot.options[:nick], *@quotes.map { |q| q.author.split.last[0,9].downcase }].compact
        c.user = @quotes.sample.author.split.first.downcase
        c.realname = @quotes.sample.display
        c.local_host = BougyBot.options.hostname
      end
      @configured = true
    end

    def start
      configure unless @configured
      @bot.start
    end
  end
end
