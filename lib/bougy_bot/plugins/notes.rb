# -*- coding: utf-8 -*-
require 'cinch'
require_relative '../../bougy_bot'
require 'cinch/cooldown'

module BougyBot
  M 'note'
  M 'user'
	module Plugins
		# Cinch Plugin to send notes
		class Notes
			include Cinch::Plugin
      include Cinch::Extensions::Authentication
      enforce_cooldown
      enable_authentication

			listen_to :channel, method: :send_notes
			match(/^!tell (\S+) (.+)/, method: :make_note, use_prefix: false)

			def make_note(m, user, message)
        return m.reply "You don't have to send me a message, I'm right here, idiot" if user == @bot.nick
        escaped = Regexp.escape user
        known_user = User.find(Sequel.or(nick: /#{escaped}/i, mask: /!#{escaped}@/i))
        return m.reply "I don't know anyone named #{user}" unless known_user
        return m.reply "You can't do that without being logged in, brah. See http://tinyurl.com/efnetphilo-register" unless authenticated? m
        if note = Note.create(from: m.user.mask.to_s, to: user.downcase, message: message) # rubocop:disable Lint/AssignmentInCondition,Metrics/LineLength
					m.reply "ok, I will let #{user} know when I see them! (Note #{note.id})"
				else
					m.reply 'Problem saving note db record'
				end
			rescue => e
        m.user.send 'Error creating note'
        m.user.send e
				e.backtrace.each do |err|
          m.user.send err
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

