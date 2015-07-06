require_relative '../bougy_bot'
require 'cinch'
require 'cinch/extensions/authentication'
if BougyBot.options.clever
  require_relative './plugins/cleverbot.rb'
  require 'cinch/plugins/news'
  require 'cinch/plugins/evalso'
  require 'cinch-karma'
  require 'cinch-urbandict'
  require 'cinch-dicebag'
  require 'cinch/plugins/fortune'
  require 'cinch/plugins/wikipedia'
  require_relative './plugins/haiku.rb'
  require 'cinch-convert'
  require 'cinch-calculate'
end

if BougyBot.options.useful
  require_relative './plugins/functions'
  require_relative './plugins/autovoice'
  require_relative './plugins/topiclock'
  require_relative './plugins/subops'
  require_relative './plugins/title'
  require_relative './plugins/quote'
  require 'cinch-weatherman'
end

require 'open-uri'
require 'nokogiri'
require 'cgi'
# Super simple google search TODO: Replace, Idjit
class Google # {{{
  include Cinch::Plugin
  match(/google (.+)/)
  def search(query)
    url = "http://www.google.com/search?q=#{CGI.escape(query)}"
    res = Nokogiri::HTML(open(url)).at('h3.r')
    title = res.text
    link = res.at('a')[:href]
    desc = res.at('./following::div').children.first.text
    CGI.unescape_html "#{title} - #{desc} (#{link})"
  rescue
    'No results found'
  end

  def execute(m, query)
    m.reply(search(query))
  end
end # }}}

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

    def plugins # rubocop:disable Metrics/MethodLength
      return @plugins if @plugins
      @plugins = [::Cinch::Plugins::UserLogin]
      if BougyBot.options.clever
        @plugins += [::Cinch::Plugins::Haiku,
                     ::Cinch::Plugins::CleverBot,
                     ::Cinch::Plugins::News,
                     ::Cinch::Plugins::EvalSo,
                     ::Cinch::Plugins::Karma,
                     ::Cinch::Plugins::UrbanDict,
                     ::Cinch::Plugins::Calculate,
                     ::Cinch::Plugins::Wikipedia,
                     ::Cinch::Plugins::Dicebag,
                     ::Cinch::Plugins::Convert,
                     ::Google,
                     ::Cinch::Plugins::Fortune]
      end

      if BougyBot.options.useful
        @plugins += [BougyBot::Plugins::Functions,
                     BougyBot::Plugins::Topiclock,
                     BougyBot::Plugins::Autovoice,
                     BougyBot::Plugins::Subops,
                     BougyBot::Plugins::Title,
                     ::Cinch::Plugins::Weatherman,
                     BougyBot::Plugins::QuoteR]
      end
      @plugins
    end

    def configure
      @quotes = (0..3).to_a.map do |_|
        BougyBot::Quote.sample
      end
      @plugs = plugins
      @bot.configure do |c|
        c.shared[:cooldown] = { config: { '#philosophy' => { global: 10, user: 20 } } }
        c.server = @server
        c.channels = @channels
        c.plugins.plugins = @plugs
        c.authentication          = ::Cinch::Configuration::Authentication.new
        c.authentication.strategy = :login # or :list / :login
        c.authentication.level    = [:admins, :subops, :users, :enemies]
        c.authentication.registration = lambda do |nick, pass|
          BougyBot::User.register nick, pass
        end
        c.authentication.fetch_user = lambda do |nick|
          BougyBot::User.find nick: nick, approved: true
        end
        c.authentication.admins =  lambda { |user| user.level.to_sym == :admin }
        c.authentication.subops =  lambda { |user| user.level.to_sym == :subop }
        c.authentication.users =   lambda { |user| user.level.to_sym == :user }
        c.authentication.enemies = lambda { |user| user.level.to_sym == :enemy }
        c.nicks = [BougyBot.options[:nick], *@quotes.map { |q| q.author.split.last[0, 9].downcase }].compact
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
