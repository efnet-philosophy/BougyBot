require_relative "../bougy_bot"
require "cinch"
require_relative "./plugins/functions"
require_relative "./plugins/autovoice"
require_relative "./plugins/title"
module BougyBot
  class Cinch
    attr_reader :bot
    def initialize(server = nil, channels = nil)
      @server = server || '2001:19f0::dead:beef:cafe'
      @bot = ::Cinch::Bot.new
      @channels = channels || ["#pho", "#philrobot"]
    end

    def configure
      @bot.configure do |c|
        c.server = @server
        c.channels = @channels
        c.plugins.plugins = [BougyBot::Plugins::Functions, Autovoice, Title]
        c.nick = "philrobot"
        c.local_host = '2001:19f0:300:3182::deaf'
      end
      @configured = true
    end

    def start
      configure unless @configured
      @bot.start
    end
  end
end
