require 'innate'
require 'json'

module BougyBot
  @default_options = { db: 'postgres://bougybot@localhost/bougybot',
                       log_level: Logger::INFO,
                       env: 'development',
                       channels: [],
                       server: 'irc.efnet.org',
                       google: { url_api_key: nil },
                       open_weather_key: nil,
                       wolfram_key: nil,
                       logfile: $stdout }

  class << self
    attr_reader :default_options
  end

  def self.loaded_options
    fname = File.join(best_config_path, best_config_filename)
    config_options = JSON.load(File.read(fname)).deep_symbolize_keys rescue {}
    @default_options.merge(config_options)
  end

  def self.best_config_path
    if File.exist?(File.join(Dir.pwd, best_config_filename))
      Dir.pwd
    else
      File.dirname(__FILE__)
    end
  end

  def self.best_config_filename
    "config/#{ENV['BougyBot_ENV'] || @default_options[:env]}.json"
  end

  include Innate::Optioned

  options.dsl do |o|
    loaded_options = BougyBot.loaded_options
    o 'Environment', :env, ENV['BougyBot_ENV'] || 'development'

    o 'Database', :db, BougyBot.options.db || ENV['BougyBot_DB'] || loaded_options[:db]

    o 'Server', :server, BougyBot.options.server || ENV['BougyBot_SERVER'] || loaded_options[:server]

    o 'Logfile', :logfile, BougyBot.options.logfile || ENV['BougyBot_LOG'] || loaded_options[:logfile] || $stdout

    o 'Log Level', :log_level, BougyBot.options.log_level || ENV['BougyBot_LogLevel'] || loaded_options[:log_level] || Logger::INFO

    o 'Debug Output', :debug, BougyBot.options.debug || ENV['BougyBot_Debug'] || loaded_options[:debug]

    o 'Debugger Hooks (pry)', :debugger, BougyBot.options.debugger || ENV['BougyBot_Debugger'] || loaded_options[:debugger]

    o 'No Long Sleep', :nodoze, BougyBot.options.nodoze || ENV['BougyBot_Nodoze'] || loaded_options[:nodoze]

    o 'Sleep', :sleeps, ([10] * 100) + ([30] * 50) + ([60] * 25) + ([100] * 10) + ([500] * 5) + [1000]

    o 'Always Talk To', :talk_to, BougyBot.options.talk_to || loaded_options[:talk_to] || ['(?-i:[A-Z\ ]{10,})'] # Always respond to screaming

    o 'Nick', :nick, BougyBot.options.nick || loaded_options[:nick] || 'pangaea'

    o 'Hostname', :hostname, BougyBot.options.hostname || loaded_options[:hostname]

    o 'Channels', :channels, BougyBot.options.channels || loaded_options[:channels]

    o 'CleverBot', :clever, BougyBot.options.clever || loaded_options[:clever] || false

    o 'Useful Bot', :useful, BougyBot.options.useful || loaded_options[:useful] || false

    o.sub :google do
      o 'API Auth Key for URL Shortening', :url_api_key, ENV['GOOGLE_URL_SHORTEN_API_KEY'] || loaded_options[:google][:url_api_key]
    end

    o 'Wolfram', :wolfram_key, BougyBot.options.wolfram_key || loaded_options[:wolfram_key]

    o 'Open Weather', :open_weather_key, BougyBot.options.open_weather_key || loaded_options[:open_weather_key]
  end
end
