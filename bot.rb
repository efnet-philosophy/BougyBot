#!/usr/bin/env ruby
require 'sequel'
require 'thread'
require 'pry-remote'
require_relative './lib/bougy_bot'
DB = Sequel.connect BougyBot.options[:db]
DB.extension :pg_array
BougyBot::M 'user'
BougyBot::M 'mask'
BougyBot::M 'channel'
BougyBot::M 'log'
BougyBot::M 'url'
BougyBot::M 'quote'
BougyBot::M 'note'
BougyBot::L 'cinch'

def clever(h = {})
  BougyBot.options.nick = nil
  channels = h[:channels] || BougyBot.options.channels
  b = BougyBot::Cinch.new((h[:server] || BougyBot.options.server), channels)
  b.bot.loggers << ::Cinch::Logger::FormattedLogger.new(File.open('clever.log', 'w'))
  b.bot.loggers = b.bot.loggers.last
  b
end

def useful(h = {})
  channels = h[:channels] || BougyBot.options.channels
  b = BougyBot::Cinch.new((h[:server] || BougyBot.options.server), channels)

  b.bot.loggers << ::Cinch::Logger::FormattedLogger.new(File.open('useful.log', 'w'))
  b.bot.loggers = b.bot.loggers.last
  b
end

if $PROGRAM_NAME == __FILE__
  require 'pry'
  u = useful
  Thread.new do |t|
    while true
      binding.pry_remote
    end
  end
  u.start
end
