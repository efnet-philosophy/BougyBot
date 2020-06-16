#!/usr/bin/env ruby
# frozen_string_literal: true
require 'sequel'
require 'thread'
require 'pry-remote'
puts "Loading library"
require_relative './lib/bougy_bot'
puts "Loading db"
require_relative './db/init'
puts "Loading cinch"
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
  puts "Setting up bot"
  u = useful
  puts "Starting up bot"
  u.start
end
