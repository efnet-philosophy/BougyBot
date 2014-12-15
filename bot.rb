#!/usr/bin/env ruby
require 'sequel'
require_relative './lib/bougy_bot'
DB = Sequel.connect BougyBot.options[:db]
DB.extension :pg_array
BougyBot::M 'user'
BougyBot::M 'mask'
BougyBot::M 'channel'
BougyBot::M 'log'
BougyBot::M 'url'
BougyBot::M 'quote'
BougyBot::L 'cinch'

if $0 == __FILE__
  require 'pry'
  BougyBot.pry
end
