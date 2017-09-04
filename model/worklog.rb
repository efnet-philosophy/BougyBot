# frozen_string_literal: true
# Bot Namespace
module BougyBot
  Worklog = Class.new Sequel::Model
  # Log of everything
  class Worklog
    set_dataset :worklogs
    many_to_one :channel
    many_to_one :user
    plugin :timestamps, create: :at, update: nil
    def self.heard(user, message, channel = nil)
      user = User.from_irc_user(user)
      attribs = { message: "<#{user.nick}> #{message}",
                  nick: user.nick,
                  user_id: user.id }
      if channel
        chan = Channel.find(name: channel.name)
        chan ||= Channel.create(name: channel.name)
        attribs[:channel_id] = chan.id
      end
      create(attribs)
    end

    def display
      log_display
    end

    def log_display
      format('ID: %s -> [%s] %s', self[:id], at.strftime('%Y/%m/%d-%H:%M:%S'), BougyBot.uncommand(message))
    end
  end
end
