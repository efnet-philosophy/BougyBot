# frozen_string_literal: true
require 'sequel'
require_relative '../lib/bougy_bot'
DB = Sequel.connect BougyBot.options[:db]
DB.extension :pg_array

BougyBot::M 'user'
BougyBot::M 'mask'
BougyBot::M 'channel'
BougyBot::M 'log'
BougyBot::M 'url'
BougyBot::M 'quote'
BougyBot::M 'note'
BougyBot::M 'vote'
BougyBot::M 'response'
