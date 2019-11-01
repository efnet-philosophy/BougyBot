# frozen_string_literal: true
require 'bcrypt'
# Bot Namespace
module BougyBot
  User = Class.new Sequel::Model
  # An user
  class User
    set_dataset :users
    plugin :timestamps, create: :at, update: :last
    one_to_many :masks
    one_to_many :chan_logs
    QUOTE_LENGTH = Sequel.function(:char_length, :message)

    def self.register(nick, pass)
      if found = find(nick: nick)
        if found.password_hash.nil?
          found.password = pass
          found.approved = true  if found.approved.nil?
          found.level    = :user if found.level.nil?
          return found.save
        end
        warn "User #{nick} already exists"
        false
      else
        new_user = new nick: nick, level: 'user', approved: true
        new_user.password = pass
        new_user.save
      end
    end

    # rubocop:disable all
    def self.quotes_for(query)
      qs = quotes(query)
      logs = ChanLog.filter(message: /\y#{query}\y/i)
        .filter { QUOTE_LENGTH > 20 }
      return [] if qs.count + logs.count == 0
      [qs, logs].map do |ds|
        ds.filter(Sequel.~(message: /^!q/)).order(Sequel.function(:random)).all rescue []
      end.flatten.sort { |a,b| rand <=> rand }
    end

    def self.quotes(query)
      nick, *query = query.split
      found = find(nick: /#{nick}/i)
      return [] unless found
      ds = found.chan_logs_dataset.filter {  QUOTE_LENGTH > 20 }
      ds = ds.filter(message: /#{query.join(" ")}/i) if query.size > 0
      ds
    end

    def self.quote(query)
      qs = quotes(query)
      return nil if qs.count == 0
      qs.limit(1).first
    end

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

    def password
      @password ||= BCrypt::Password.new(password_hash)
    end

    def password=(new_password)
      @password = BCrypt::Password.create(new_password)
      self.password_hash = @password
    end

    def authenticate(pass)
      self[:last] = Time.now
      save
      password == pass
    end
  end
end
