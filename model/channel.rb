# frozen_string_literal: true
# Namespace
module BougyBot
  Channel = Class.new Sequel::Model
  # Channel records
  class Channel
    plugin :timestamps, create: :at, update: nil
    set_dataset :channels
    one_to_many :votes
  end
end
