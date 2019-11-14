# frozen_string_literal: true
require 'sequel'
require_relative '../lib/bougy_bot'
require 'georuby'
require 'geo_ruby/ewk'
DB = Sequel.connect BougyBot.options[:db]
DB.extension :pg_array
DB.extension :postgis_georuby

BougyBot::M 'user'
BougyBot::M 'mask'
BougyBot::M 'channel'
BougyBot::M 'log'
BougyBot::M 'url'
BougyBot::M 'quote'
BougyBot::M 'note'
BougyBot::M 'vote'
BougyBot::M 'response'
