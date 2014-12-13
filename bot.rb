#!/usr/bin/env ruby
require 'sequel'
require_relative './lib/bougy_bot'
Sequel.connect BougyBot.options[:db]
BougyBot::M 'url'
BougyBot::L 'cinch'

if $0 == __FILE__
  require 'pry'
  BougyBot.pry
end
