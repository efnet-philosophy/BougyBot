# Bot Namespace
module BougyBot
  ChanLog = Class.new Sequel::Model
  # Log of everything
  class ChanLog
    set_dataset :channel_logs
    many_to_one :channel
    many_to_one :user
    plugin :timestamps, create: :at, update: nil
    def self.heard(channel, user, message)
      chan = Channel.find(name: channel.name)
      chan ||= Channel.create(name: channel.name)
      user = User.from_irc_user(user)
      create(message: message,
             nick: user.nick,
             user_id: user.id,
             channel_id: chan.id)
    end

    def display
      format('%s -- %s', BougyBot.uncommand(message), nick)
    end
  end
end
