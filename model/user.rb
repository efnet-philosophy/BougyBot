# Bot Namespace
module BougyBot
  User = Class.new Sequel::Model
  # An user
  class User
    set_dataset :users
    plugin :timestamps, create: :at, update: :last
    one_to_many :masks
    one_to_many :chan_logs
    def self.from_irc_user(user)
      found = find(nick: user.nick)
      return found if found
      mask = Mask.all.detect { |m| user.match m }
      return mask.user if mask
      create(nick: user.nick, mask: user.mask)
    end

    def after_create
      super
      Mask.create(mask: mask, user_id: self[:id])
    end
  end
end
