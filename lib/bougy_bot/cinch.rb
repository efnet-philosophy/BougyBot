require_relative '../bougy_bot'
require 'cinch'
require 'cinch/extensions/authentication'
if BougyBot.options.clever
  require_relative './plugins/cleverbot.rb'
  require 'cinch-karma'
  require_relative './plugins/haiku.rb'
end

if BougyBot.options.useful
  require_relative './plugins/functions'
  require_relative './plugins/autovoice'
  require_relative './plugins/wolfram'
  require_relative './plugins/times'
  require 'cinch-dicebag'
  require 'cinch-convert'
  # require 'cinch-calculate'
  require 'cinch/plugins/fortune'
  require 'cinch/plugins/wikipedia'
  require 'cinch/plugins/news'
  require 'cinch-urbandict'
  require_relative './plugins/topiclock'
  require_relative './plugins/subops'
  require_relative './plugins/title'
  require_relative './plugins/quote'
  require_relative './plugins/notes'
  require_relative './plugins/votes'
  #require_relative './plugins/markov'
  require_relative './plugins/weatherman'
  #require 'cinch-lastactive'
  require 'cinch-seen'
end

require_relative './google_search'
require 'cinch/cooldown'

# Super simple google search TODO: Replace, Idjit
class Google # {{{
  include Cinch::Plugin
  enforce_cooldown
  set :prefix, '?'
  match(/rules$/, method: :rules)
  match(/wtf$/, method: :wiki)
  match(/subops$/, method: :subops)
  match(/\?\s*(.+)/)

  def search(query)
    BougyBot::GoogleSearch.new(query).display
  rescue => e
    warn "Error: #{e}"
    unless @nopry
      require 'pry'
      binding.pry if @pry
    end
    'No results found'
  end

  def subops(m)
    m.reply('Wiki: https://github.com/efnet-philosophy/efnet-philosophy.github.io/wiki/Subops')
  end

  def wiki(m)
    m.reply('Wiki: https://github.com/efnet-philosophy/efnet-philosophy.github.io/wiki')
  end

  def rules(m)
    m.reply('Rules of the channel: https://github.com/efnet-philosophy/efnet-philosophy.github.io/wiki/Rules-of-the-Channel')
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
      @server = server || 'irc.efnet.org'
      @bot = ::Cinch::Bot.new
      @channels = channels || ['#pho', '#philrobot']
    end

    def plugins # rubocop:disable Metrics/MethodLength
      return @plugins if @plugins
      @plugins = [::Cinch::Plugins::UserLogin]
      if BougyBot.options.clever
        @plugins += [::Cinch::Plugins::Haiku,
                     ::Cinch::Plugins::CleverBot,
                     ::Cinch::Plugins::Karma,
                     ::Cinch::Plugins::Dicebag]
      end

      if BougyBot.options.useful
        @plugins += [BougyBot::Plugins::Functions,
                     BougyBot::Plugins::Topiclock,
                     ::Cinch::Plugins::News,
                     ::Cinch::Plugins::Wikipedia,
                     ::Cinch::Plugins::Dicebag,
                     BougyBot::Plugins::Autovoice,
                     BougyBot::Plugins::Times,
                     BougyBot::Plugins::Subops,
                     BougyBot::Plugins::Title,
                     BougyBot::Plugins::Weatherman,
                     BougyBot::Plugins::Wolfram,
                     BougyBot::Plugins::Notes,
                     BougyBot::Plugins::Votes,
                     ::Cinch::Plugins::Convert,
                     ::Google,
                     ::Cinch::Plugins::Fortune,
                     ::Cinch::Plugins::Seen,
                     ::Cinch::Plugins::UrbanDict,
                     BougyBot::Plugins::QuoteR]
                     # BougyBot::Plugins::Markov
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
        c.ssl.use = false
        c.port = 6667
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
          BougyBot::User.find(nick: nick, approved: true)
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
    rescue EOFError => e
      $stderr.puts e
      e.backtrace.each { |d| $stderr.puts "\t#{d}" }
      exit 69
    end
  end
end
