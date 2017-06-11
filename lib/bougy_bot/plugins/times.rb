# -*- coding: utf-8 -*-
require 'cinch'
require_relative '../../bougy_bot'
require 'cinch/cooldown'

module BougyBot
  M 'zone'
	module Plugins
		# Cinch Plugin to send notes
		class Times
			include Cinch::Plugin
      enforce_cooldown

			match(/^!time_at (.+)/, method: :time, use_prefix: false)

			def time(m, message)
        zone = BougyBot::Zone.lookup(message)
        return "Cannot find #{message}" unless zone
        m.reply "The time in #{zone.name}, #{zone.country} is #{zone.time}"
			rescue => e
        m.user.send 'Error getting time'
        m.user.send e
				e.backtrace.each do |err|
          m.user.send err
				end
			end
		end
  end
end

