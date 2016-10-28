# -*- coding: utf-8 -*-
require 'cinch'
require_relative '../../bougy_bot'
require 'cinch/cooldown'

module BougyBot
  M 'note'
	module Plugins
		# Cinch Plugin to send notes
		class Notes
			include Cinch::Plugin
      enforce_cooldown

			listen_to :channel, method: :send_notes
			match(/^!tell (\w+) (.+)/, method: :make_note, use_prefix: false)

			def make_note(m, user, message)
				if note = Note.create(from: m.user.nick, to: user.downcase, message: message) # rubocop:disable Lint/AssignmentInCondition,Metrics/LineLength
					m.reply "ok, I will let #{user} know when I see them! (Note #{note.id})"
				else
					m.reply 'Problem saving note db record'
				end
			rescue => e
				m.reply 'Error creating note'
				m.reply e
				e.backtrace.each do |err|
					m.reply err
				end
			end

			private

			def send_notes(m)
				nick = m.user.nick.downcase
				user = m.user.user.downcase
				notes = Note.where to: [nick, user], sent: false
				count = notes.count
				return unless count > 0
				m.channel.send "Hey there, #{nick}! You've got #{count} note#{count > 1 ? 's' : ''}, sending in pm"
				notes.each do |note|
					m.user.send("#{note.from} asked me to tell you '#{note.message}'")
					note.update sent: true
				end
			end
		end
  end
end

